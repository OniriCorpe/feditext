// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class StatusesViewModel: ObservableObject {
    @Published private(set) var statusSections = [[Status]]()
    @Published var alertItem: AlertItem?
    @Published private(set) var loading = false
    private(set) var maintainScrollPositionOfStatusID: String?
    private let statusListService: StatusListService
    private var statusViewModelCache = [Status: (StatusViewModel, AnyCancellable)]()
    private var cancellables = Set<AnyCancellable>()

    init(statusListService: StatusListService) {
        self.statusListService = statusListService

        statusListService.statusSections
            .handleEvents(receiveOutput: { [weak self] in
                self?.determineIfScrollPositionShouldBeMaintained(newStatusSections: $0)
                self?.cleanViewModelCache(newStatusSections: $0)
            })
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$statusSections)
    }
}

extension StatusesViewModel {
    var contextParent: Status? { statusListService.contextParent }

    func request(maxID: String? = nil, minID: String? = nil) {
        statusListService.request(maxID: maxID, minID: minID)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.loading = true },
                receiveCompletion: { [weak self] _ in self?.loading = false })
            .sink {}
            .store(in: &cancellables)
    }

    func statusViewModel(status: Status) -> StatusViewModel {
        var statusViewModel: StatusViewModel

        if let cachedViewModel = statusViewModelCache[status]?.0 {
            statusViewModel = cachedViewModel
        } else {
            statusViewModel = StatusViewModel(statusService: statusListService.statusService(status: status))
            statusViewModelCache[status] = (statusViewModel, statusViewModel.events
                .flatMap { $0 }
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink {})
        }

        statusViewModel.isContextParent = status == contextParent
        statusViewModel.isPinned = statusListService.isPinned(status: status)
        statusViewModel.isReplyInContext = statusListService.isReplyInContext(status: status)
        statusViewModel.hasReplyFollowing = statusListService.hasReplyFollowing(status: status)

        return statusViewModel
    }

    func contextViewModel(status: Status) -> StatusesViewModel {
        StatusesViewModel(statusListService: statusListService.contextService(status: status))
    }
}

private extension StatusesViewModel {
    func determineIfScrollPositionShouldBeMaintained(newStatusSections: [[Status]]) {
        maintainScrollPositionOfStatusID = nil // clear old value

        // Maintain scroll position of parent after initial load of context
        if let contextParent = contextParent, statusSections == [[], [contextParent], []] {
            maintainScrollPositionOfStatusID = contextParent.id
        }
    }

    func cleanViewModelCache(newStatusSections: [[Status]]) {
        let newStatuses = Set(newStatusSections.reduce([], +))

        statusViewModelCache = statusViewModelCache.filter { newStatuses.contains($0.key) }
    }
}