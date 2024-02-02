// Copyright © 2023 Vyr Cossont. All rights reserved.

import CoreText
import Foundation

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

public extension Siren {
    /// Given an attributed string with Foundation and Siren attributes,
    /// convert them to AppKit/UIKit attributes for display,
    /// using the provided font descriptor.
    static func format(_ attributed: AttributedString, descriptor: CTFontDescriptor) -> AttributedString {
        var attributed = attributed

        let fontSize: CGFloat
        if let fontSizeNumber = CTFontDescriptorCopyAttribute(descriptor, kCTFontSizeAttribute) as? NSNumber {
            fontSize = .init(truncating: fontSizeNumber)
        } else {
            fontSize = 0
        }
        let defaultFont = CTFontCreateWithFontDescriptor(descriptor, 0, nil)
        #if canImport(SwiftUI)
        let swiftUIDefaultFont = Font(defaultFont)
        #endif

        for run in attributed.runs {
            if let intent = run.inlinePresentationIntent {
                var traits: CTFontSymbolicTraits = []
                if intent.contains(.stronglyEmphasized) {
                    traits.insert(.traitBold)
                }
                if intent.contains(.emphasized) {
                    traits.insert(.traitItalic)
                }
                if intent.contains(.code) {
                    traits.insert(.traitMonoSpace)
                }
                if let descriptorWithTraits = CTFontDescriptorCreateCopyWithSymbolicTraits(
                    descriptor,
                    traits,
                    .traitClassMask
                ) {
                    let font = CTFontCreateWithFontDescriptor(descriptorWithTraits, 0, nil)
                    #if canImport(AppKit)
                    attributed[run.range].appKit.font = font
                    #elseif canImport(UIKit)
                    attributed[run.range].uiKit.font = font
                    #endif
                    #if canImport(SwiftUI)
                    attributed[run.range].swiftUI.font = .init(font)
                    #endif
                }
            } else {
                // Ensure that every run has a font.
                #if canImport(AppKit)
                attributed[run.range].appKit.font = defaultFont
                #elseif canImport(UIKit)
                attributed[run.range].uiKit.font = defaultFont
                #endif
                #if canImport(SwiftUI)
                attributed[run.range].swiftUI.font = swiftUIDefaultFont
                #endif
            }

            if let styles = run.styles {
                if styles.contains(.strikethru) {
                    #if canImport(AppKit)
                    attributed[run.range].appKit.strikethroughStyle = .single
                    #elseif canImport(UIKit)
                    attributed[run.range].uiKit.strikethroughStyle = .single
                    #endif
                    #if canImport(SwiftUI)
                    attributed[run.range].swiftUI.strikethroughStyle = .single
                    #endif
                }
                if styles.contains(.underline) {
                    #if canImport(AppKit)
                    attributed[run.range].appKit.underlineStyle = .single
                    #elseif canImport(UIKit)
                    attributed[run.range].uiKit.underlineStyle = .single
                    #endif
                    #if canImport(SwiftUI)
                    attributed[run.range].swiftUI.underlineStyle = .single
                    #endif
                }
                // TODO: (Vyr) handle .small, .sub, and .sup
            }
        }

        var insertions = [(String, at: AttributedString.Index)]()

        for (intent, range) in attributed.runs[\.presentationIntent] {
            if let intent = intent {
                let indent = CGFloat(intent.indentationLevel) * fontSize

                #if canImport(AppKit) || canImport(UIKit)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.setParagraphStyle(.default)
                paragraphStyle.firstLineHeadIndent = indent
                paragraphStyle.headIndent = indent
                paragraphStyle.tabStops = []
                // TODO: (Vyr) HACK: this plus the leading tabs on `listDecoration` make lists look okay,
                //  but I have no idea why. `fontSize * 1` doesn't work. This may break for any reason. See below.
                paragraphStyle.defaultTabInterval = fontSize * 2
                attributed[range].paragraphStyle = paragraphStyle
                #endif

                var listType: ListType?
                var listDecoration: String?
                var newlines: String?
                var preformatted = false
                // Order: parents to children.
                for component in intent.components.reversed() {
                    switch component.kind {
                    case .paragraph, .blockQuote:
                        newlines = "\n\n"
                    case .orderedList:
                        listType = .ordered
                    case .unorderedList:
                        listType = .unordered
                    case let .listItem(ordinal):
                        // If we're not inside a list, just skip this.
                        // The sanitizer may or may not correct that kind of malformed HTML.
                        guard let listType = listType else { continue }

                        // TODO: (Vyr) the first list item in some lists is normal,
                        //  but subsequent items are indented and shouldn't be:
                        //  - fine: https://infosec.exchange/@vyr/111378145558735113
                        //  - not fine: https://demon.social/@vyr/111387309365750057
                        switch listType {
                        case .ordered:
                            listDecoration = "\t\(ordinal).\t"
                        case .unordered:
                            listDecoration = "\t•\t"
                        }
                        newlines = "\n"
                    case .codeBlock:
                        preformatted = true
                    default:
                        break
                    }
                }
                if let listDecoration = listDecoration {
                    insertions.append((listDecoration, at: range.lowerBound))
                }
                if !preformatted {
                    if let newlines = newlines {
                        insertions.append((newlines, at: range.upperBound))
                    }
                }
            } else {
                // Ensure that every run has a paragraph style.
                #if canImport(AppKit)
                attributed[range].appKit.paragraphStyle = .default
                #elseif canImport(UIKit)
                attributed[range].uiKit.paragraphStyle = .default
                #endif
                // SwiftUI doesn't have a paragraph style attribute.
                insertions.append(("\n\n", at: range.upperBound))
            }
        }

        for (string, index) in insertions.reversed() {
            attributed.characters.insert(contentsOf: string, at: index)
        }

        return attributed
    }

    private enum ListType {
        case ordered
        case unordered
    }

    #if canImport(AppKit)
    static func format(_ attributed: AttributedString, textStyle: NSFont.TextStyle) -> AttributedString {
        format(attributed, descriptor: NSFontDescriptor.preferredFontDescriptor(forTextStyle: textStyle))
    }

    #if canImport(SwiftUI)
    static func format(_ attributed: AttributedString, textStyle: SwiftUI.Font.TextStyle) -> AttributedString {
        format(attributed, descriptor: textStyle.descriptor)
    }
    #endif
    #elseif canImport(UIKit)
    static func format(_ attributed: AttributedString, textStyle: UIFont.TextStyle) -> AttributedString {
        format(attributed, descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle))
    }

    #if canImport(SwiftUI)
    static func format(_ attributed: AttributedString, textStyle: SwiftUI.Font.TextStyle) -> AttributedString {
        format(attributed, descriptor: textStyle.descriptor)
    }
    #endif
    #endif
}

#if canImport(SwiftUI)
#if canImport(AppKit)
extension SwiftUI.Font.TextStyle {
    var descriptor: CTFontDescriptor {
        let textStyle: NSFont.TextStyle
        switch self {
        case .largeTitle:
            textStyle = .largeTitle
        case .title:
            textStyle = .title1
        case .title2:
            textStyle = .title2
        case .title3:
            textStyle = .title3
        case .headline:
            textStyle = .headline
        case .subheadline:
            textStyle = .subheadline
        case .body:
            textStyle = .body
        case .callout:
            textStyle = .callout
        case .footnote:
            textStyle = .footnote
        case .caption:
            textStyle = .caption1
        case .caption2:
            textStyle = .caption2
        @unknown default:
            #if DEBUG
            fatalError("Unknown SwiftUI.Font.TextStyle: \(self)")
            #else
            return NSFont.systemFont(ofSize: 0).fontDescriptor
            #endif
        }
        return NSFontDescriptor.preferredFontDescriptor(forTextStyle: textStyle)
    }
}
#elseif canImport(UIKit)
extension SwiftUI.Font.TextStyle {
    var descriptor: CTFontDescriptor {
        let textStyle: UIFont.TextStyle
        switch self {
        case .largeTitle:
            textStyle = .largeTitle
        case .title:
            textStyle = .title1
        case .title2:
            textStyle = .title2
        case .title3:
            textStyle = .title3
        case .headline:
            textStyle = .headline
        case .subheadline:
            textStyle = .subheadline
        case .body:
            textStyle = .body
        case .callout:
            textStyle = .callout
        case .footnote:
            textStyle = .footnote
        case .caption:
            textStyle = .caption1
        case .caption2:
            textStyle = .caption2
        @unknown default:
            #if DEBUG
            fatalError("Unknown SwiftUI.Font.TextStyle: \(self)")
            #else
            return UIFont.systemFont(ofSize: 0).fontDescriptor
            #endif
        }
        return UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
    }
}
#endif
#endif

#if canImport(AppKit) || canImport(UIKit)
// Conform `NSParagraphStyle` to `Sendable` so we can assign it to `.paragraphStyle` without compiler warnings.
// source: trust me bro
extension NSParagraphStyle: @unchecked Sendable {}
#endif
