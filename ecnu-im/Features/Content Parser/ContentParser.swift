//
//  ContentParser.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/25.
//

import CoreGraphics
import Foundation
import MarkdownKit
import Regex
import UIKit

protocol ContentBlockUIView: UIView {}

class ContentParser {
    private var content: String = ""
    private var configuration: ParseConfiguration

    private var contentBlocks: [ContentBlock]?

    private var updateLayout: (() -> Void)?

    private static func preprocess(content: String) -> String {
        // Merge continues '>', because flarum does it.
        let _r1 = Regex("(^>.*?)\n\\s*?\n>")
        var content = content.replacingAll(matching: _r1, with: "$1\n>")

        // Add '>' for continues lines
        var processedLines: [String] = []
        content
            .split(separator: "\n", omittingEmptySubsequences: false)
            .enumerated()
            .forEach { index, element in
                if index > 0, processedLines[index - 1].starts(with: ">"), !element.starts(with: ">"), element.contains(where: { !$0.isWhitespace }), !element.starts(with: "```") {
                    processedLines.append(">" + element)
                } else {
                    processedLines.append(String(element))
                }
            }
        content = processedLines.joined(separator: "\n")

        return content
    }

    init(content: String, configuration: ParseConfiguration, updateLayout: (() -> Void)?) {
        self.content = Self.preprocess(content: content)
        self.configuration = configuration
        self.updateLayout = updateLayout
    }

    private static func parseListToAttributedString(list: ContentBlockList, level: Int) -> NSAttributedString {
        let styleStack = ContentTextStyleStack()
        let attributedString = NSMutableAttributedString()

        let indentWhitespaces: String = {
            if level == 0 {
                return "  "
            } else {
                return String(repeating: "    ", count: level + 1)
            }
        }()

        var orderOffset = 0
        for (index, item) in list.items.enumerated() {
            let leadingCharacter: RichText = {
                switch item {
                case .text:
                    switch list.listType {
                    case .bullet:
                        return .bold(.plain("\u{2022} "))
                    case let .ordered(number):
                        orderOffset += 1
                        return .bold(.plain("\(number + orderOffset - 1). "))
                    }
                case .list:
                    return .empty
                }
            }()
            switch item {
            case let .text(richText):
                let itemRichText = RichText.concat([
                    .plain(indentWhitespaces), .bold(.plain("")),
                    leadingCharacter,
                    richText,
                    index != list.items.count - 1 ? .plain("\n") : .empty,
                ])
                attributedString.append(itemRichText.attributedString(styleStack: styleStack))
            case let .list(contentBlockList):
                attributedString.append(parseListToAttributedString(list: contentBlockList, level: level + 1))
                if index != list.items.count - 1 {
                    attributedString.append(.init(string: "\n"))
                }
            }
        }

        return attributedString
    }

    private func _parseContentBlocksToContentItems(contentBlocks: [ContentBlock], initStyles: [ContentTextStyle] = []) -> [ContentBlockUIView] {
        var contentItems: [ContentBlockUIView] = []

        for contentBlock in contentBlocks {
            switch contentBlock {
            case let .paragraph(richText):
                let styleStack = ContentTextStyleStack(items: initStyles)
                let attributedString = richText.attributedString(styleStack: styleStack)
                contentItems.append(ContentItemParagraphUIView(attributedText: attributedString))
            case let .header(richText, level):
                let styleStack = ContentTextStyleStack(items: initStyles)
                styleStack.push(.fontSize(-2.0 * CGFloat(level) + 30.0))
                styleStack.push(.bold)
                let attributedString = richText.attributedString(styleStack: styleStack)
                contentItems.append(ContentItemParagraphUIView(attributedText: attributedString))
            case let .blockQuote(contentBlocks):
                let subContentItems = _parseContentBlocksToContentItems(contentBlocks: contentBlocks, initStyles: [
                    .textColor(Asset.DynamicColors.dynamicBlack.color.withAlphaComponent(0.7)),
                ])
                if subContentItems.count > 0 {
                    contentItems.append(ContentItemBlockquoteUIView(contentItems: subContentItems))
                }
            case let .list(contentBlockList):
                let attributedString = Self.parseListToAttributedString(list: contentBlockList, level: 0)
                contentItems.append(ContentItemParagraphUIView(attributedText: attributedString))
            case .divider:
                contentItems.append(ContentItemDividerUIView())
            case let .codeBlock(optional, string):
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 2
                paragraphStyle.paragraphSpacing = 2
                paragraphStyle.paragraphSpacingBefore = 2
                let attributes: [NSAttributedString.Key: Any] = [
                    NSAttributedString.Key.font: Font.monospace(17),
                    NSAttributedString.Key.foregroundColor: Asset.DynamicColors.dynamicBlack.color,
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                ]
                let trimmedString = string.trimmingCharacters(in: .newlines)
                let attributedString: NSAttributedString = .init(string: trimmedString, attributes: attributes)
                contentItems.append(ContentItemCodeBlockUIView(attributedText: attributedString))
            case let .linkPreview(link):
                if let url = URL(string: link) {
                    contentItems.append(ContentItemLinkPreview(link: url, updateLayout: updateLayout))
                }
            case let .image(url):
                if let url = URL(string: url) {
                    contentItems.append(ContentItemSingleImageUIView(url: url, onTapAction: {
                        ImageBrowser.shared.present(imageURLs: $1, selectedImageIndex: $0)
                    }, updateLayout: updateLayout))
                }
            case let .images(urls):
                let urls = urls.compactMap { URL(string: $0) }
                if urls.count > 0 {
                    contentItems.append(ContentItemImagesGridUIView(urls: urls, configuration: configuration, updateLayout: updateLayout))
                }
            case let .table(rows):
                break
            }
        }

        return contentItems
    }

    func parse() -> [ContentBlockUIView] {
        let markdown = MarkdownParser.standard.parse(content)
        guard case let .document(topLevelBlocks) = markdown else {
            return []
        }

        if contentBlocks == nil {
            contentBlocks = ContentBlock.parseFrom(blocks: topLevelBlocks)
        }

        return _parseContentBlocksToContentItems(contentBlocks: contentBlocks!)
    }

    struct ContentExcerpt {
        struct ContentExcerptConfiguration {
            var textLengthMax: Int
            var textLineMax: Int
            var imageCountMax: Int
        }

        var text: String
        var images: [String]
    }

    func getExcerptContent(configuration: ContentExcerpt.ContentExcerptConfiguration) -> ContentExcerpt {
        let markdown = MarkdownParser.standard.parse(content)
        guard case let .document(topLevelBlocks) = markdown else {
            return .init(text: "", images: [])
        }

        if contentBlocks == nil {
            contentBlocks = ContentBlock.parseFrom(blocks: topLevelBlocks)
        }

        var text = ""
        var images: [String] = []
        for contentBlock in contentBlocks! {
            if text.count < configuration.textLengthMax {
                text += contentBlock.excerptText
            }
            if case let .image(url) = contentBlock {
                images.append(url)
            } else if case let .images(urls) = contentBlock {
                images.append(contentsOf: urls)
            }
        }

        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var numberOfLines = 0
        var maxIndex = text.count - 1
        let textCharactersArray: [Character] = Array(text)
        for (index, textCharacter) in textCharactersArray.enumerated() {
            if textCharacter == "\n" {
                numberOfLines += 1
            }
            if numberOfLines == configuration.textLineMax {
                maxIndex = index
            }
        }

        let finalString = String(Array(textCharactersArray.prefix(maxIndex + 1))).prefix(configuration.textLengthMax)

        return ContentExcerpt(text: String(finalString),
                              images: Array(images.prefix(configuration.imageCountMax)))
    }
}
