// Copyright © 2021 Metabolist. All rights reserved.

import Mastodon
import UIKit
import ViewModels

// TODO: (Vyr) reactions: update this to share the new add button used by `StatusReactionsView`
/// Show an announcment with emoji reactions.
/// - See: ``StatusReactionsView`` (derived from this)
final class AnnouncementView: UIView {
    private let contentTextView = TouchFallthroughTextView()
    private let reactionButton = UIButton()
    private let reactionsCollectionView = ReactionsCollectionView()
    private var announcementConfiguration: AnnouncementContentConfiguration

    init(configuration: AnnouncementContentConfiguration) {
        announcementConfiguration = configuration

        super.init(frame: .zero)

        initialSetup()
        applyAnnouncementConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, Reaction> = {
        let cellRegistration = UICollectionView.CellRegistration
        <ReactionCollectionViewCell, Reaction> { [weak self] in
            guard let self = self else { return }

            $0.viewModel = ReactionViewModel(
                reaction: $2,
                emojis: self.announcementConfiguration.viewModel.announcement.emojis,
                identityContext: self.announcementConfiguration.viewModel.identityContext
            )
        }

        let dataSource = UICollectionViewDiffableDataSource
        <Int, Reaction>(collectionView: reactionsCollectionView) {
            $0.dequeueConfiguredReusableCell(using: cellRegistration, for: $1, item: $2)
        }

        return dataSource
    }()
}

extension AnnouncementView {
    static func estimatedHeight(width: CGFloat, announcement: Announcement) -> CGFloat {
        UITableView.automaticDimension
    }

    func dismissIfUnread() {
        announcementConfiguration.viewModel.dismissIfUnread()
    }
}

extension AnnouncementView: UIContentView {
    var configuration: UIContentConfiguration {
        get { announcementConfiguration }
        set {
            guard let announcementConfiguration = newValue as? AnnouncementContentConfiguration else { return }

            self.announcementConfiguration = announcementConfiguration

            applyAnnouncementConfiguration()
        }
    }
}

extension AnnouncementView: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction:
            announcementConfiguration.viewModel.urlSelected(URL)
            return false
        case .preview: return false
        case .presentActions: return false
        @unknown default: return false
        }
    }
}

extension AnnouncementView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let reaction = dataSource.itemIdentifier(for: indexPath) else { return }

        if reaction.me {
            announcementConfiguration.viewModel.removeReaction(name: reaction.name)
        } else {
            announcementConfiguration.viewModel.addReaction(name: reaction.name)
        }

        UISelectionFeedbackGenerator().selectionChanged()
    }
}

private extension AnnouncementView {
    func initialSetup() {
        let stackView = UIStackView()

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .defaultSpacing

        contentTextView.adjustsFontForContentSizeCategory = true
        contentTextView.backgroundColor = .clear
        contentTextView.delegate = self
        stackView.addArrangedSubview(contentTextView)

        let reactionStackView = UIStackView()

        stackView.addArrangedSubview(reactionStackView)
        reactionStackView.spacing = .defaultSpacing
        reactionStackView.alignment = .top

        reactionStackView.addArrangedSubview(reactionButton)
        reactionButton.tag = UUID().hashValue
        reactionButton.accessibilityLabel = NSLocalizedString("announcement.insert-emoji", comment: "")
        reactionButton.setImage(
            UIImage(systemName: "plus.circle", withConfiguration: UIImage.SymbolConfiguration(scale: .large)),
            for: .normal)
        reactionButton.addAction(
            UIAction { [weak self] _ in
                guard let self = self else { return }

                self.announcementConfiguration.viewModel.presentEmojiPicker(sourceViewTag: self.reactionButton.tag)
            },
            for: .touchUpInside)

        reactionStackView.addArrangedSubview(reactionsCollectionView)
        reactionsCollectionView.delegate = self
        reactionsCollectionView.setContentCompressionResistancePriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor),
            reactionButton.widthAnchor.constraint(equalToConstant: .minimumButtonDimension),
            reactionButton.heightAnchor.constraint(equalToConstant: .minimumButtonDimension)
        ])
    }

    func applyAnnouncementConfiguration() {
        let viewModel = announcementConfiguration.viewModel
        let mutableContent = NSMutableAttributedString(attributedString: viewModel.announcement.content.attributed)
        let contentFont = UIFont.preferredFont(forTextStyle: .callout)
        let contentRange = NSRange(location: 0, length: mutableContent.length)

        mutableContent.removeAttribute(.font, range: contentRange)
        mutableContent.addAttributes(
            [.font: contentFont, .foregroundColor: UIColor.label],
            range: contentRange)
        mutableContent.insert(emojis: viewModel.announcement.emojis,
                              view: contentTextView,
                              identityContext: viewModel.identityContext)
        mutableContent.resizeAttachments(toLineHeight: contentFont.lineHeight)
        contentTextView.attributedText = mutableContent

        var snapshot = NSDiffableDataSourceSnapshot<Int, Reaction>()

        snapshot.appendSections([0])
        snapshot.appendItems(viewModel.announcement.reactions, toSection: 0)

        if snapshot.itemIdentifiers != dataSource.snapshot().itemIdentifiers {
            dataSource.apply(snapshot, animatingDifferences: false) {
                if self.contentTextView.frame.size == .zero
                    || self.contentTextView.contentSize.height < self.contentTextView.frame.height {
                    viewModel.reload()
                }
            }
        }
    }
}
