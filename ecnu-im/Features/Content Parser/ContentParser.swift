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

class ContentParser {
    private var content: String = ""
    private var configuration: ParseConfiguration

    private var contentBlocks: [ContentBlock]?

    private static let magicStringLink = "MagicStringLink-1650947"
    private static let magicStringImage = "MagicStringImage-1650947"
    
    private static func preprocess(content: String) -> String {
        let _r1 = Regex("(^>.*?)\n\\s*?\n>")
        let content = content.replacingAll(matching: _r1, with: "$1\n>")
        return content
    }

    /// Embed naked link and image url in `[]()` and `![]()`, and make all image urls and naked links in a single line.
    /// We embed all links inside `[]()`, and then re-extract those double embedded links.
    /// Next add `!` mark before all `.jp(e)g`, `.png` and `.gif` links.
    /// Finally, make all image urls and naked links in a single line.
    /// - Parameter content: original markdown content
    /// - Returns: processed markdown content
    private func processParagraph(content: String) -> String {
        // A strong regex to match urls(and possible alt text)
        let _us = "(https?:\\/\\/)(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b([-a-zA-Z0-9()@:%_\\+.~#?&\\/\\/=]*)"

        // Remove possible alt text
        let _us_with_alt_text = "\\[(.*?)\\]\\((\(_us))(\\s+.*?)?\\)"
        let _r0 = try! Regex(string: "\(_us_with_alt_text)", options: .ignoreCase)
        var content = content.replacingAll(matching: _r0, with: "[$1]($2)")

        let _r1 = try! Regex(string: "(\(_us))", options: .ignoreCase)
        content = content.replacingAll(matching: _r1, with: "[\(Self.magicStringLink)]($1)")

        let _r2 = try! Regex(string: "\\[(.*?)\\]\\(\\[\(Self.magicStringLink)\\]\\((.*?)\\)\\s*?\\)", options: .ignoreCase)
        content = content.replacingAll(matching: _r2, with: "[$1]($2)")

        let _r3 = try! Regex(string: "\\[\(Self.magicStringLink)\\]\\((\(_us)\\.(png|jpe?g|gif))\\)", options: .ignoreCase)
        content = content.replacingAll(matching: _r3, with: "![\(Self.magicStringImage)]($1)")

        return content
    }

    init(content: String, configuration: ParseConfiguration) {
        self.content = Self.preprocess(content: content)
        self.configuration = configuration
    }

    private func _parseTextToRichText(text: Text) -> RichText {
        var richTextArray: [RichText] = []
        for fragment in text {
            switch fragment {
            case let .text(text):
                richTextArray.append(.plain(String(text)))
            case let .code(text):
                richTextArray.append(.codeInline(String(text)))
            case let .emph(text):
                richTextArray.append(.italic(_parseTextToRichText(text: text)))
            case let .strong(text):
                richTextArray.append(.bold(_parseTextToRichText(text: text)))
            case let .link(text, url, _):
                if let url = url {
                    richTextArray.append(.link(text: _parseTextToRichText(text: text), url: url))
                }
            case let .autolink(_, link):
                richTextArray.append(.plain(String(link)))
            case .image:
                // Processed in previous level
                break
            case let .html(text):
                richTextArray.append(.codeInline(String(text)))
            case let .delimiter(character, number, _):
                richTextArray.append(.plain(String(repeating: character, count: number)))
            case .softLineBreak:
                richTextArray.append(.plain("\n"))
            case .hardLineBreak:
                richTextArray.append(.plain("\n"))
            case let .custom(fragment):
                // TODO: Custom fragment
                print(fragment)
            }
        }

        if richTextArray.count > 1 {
            return .concat(richTextArray)
        } else if richTextArray.count == 1 {
            return richTextArray[0]
        } else {
            return .empty
        }
    }

    private func _partList(block: Block) -> ContentBlockList? {
        if case let .list(topListType, _, topBlocks) = block {
            var topListItems: [ContentBlockList.ContentListItem] = []
            for topBlock in topBlocks {
                if case let .listItem(_, _, subListBlocks) = topBlock {
                    for subListBlock in subListBlocks {
                        if case let .paragraph(text) = subListBlock {
                            topListItems.append(.text(_parseTextToRichText(text: text)))
                        } else if case .list = subListBlock, let list = _partList(block: subListBlock) {
                            topListItems.append(.list(list))
                        }
                    }
                }
            }
            return .init(items: topListItems, listType: topListType == nil ? .bullet : .ordered(topListType!))
        }
        return nil
    }

    private func _parse(block: Block) -> [ContentBlock] {
        switch block {
        case .document, .definitionList, .referenceDef:
            // TODO: Or, we need to parse them as normal text in case...
            break
        case let .paragraph(text):
            // A strong regex to match urls
            let content = processParagraph(content: text.description)

            let markdown = MarkdownParser.standard.parse(content)
            if case let .document(blocks) = markdown,
               blocks.count == 1,
               case let .paragraph(text) = blocks[0] {
                var paragraphContentBlocks: [ContentBlock] = []
                var tempText = Text()

                let processTempText = {
                    if tempText.count > 0 {
                        if let _ = tempText.rawDescription.first(where: { !$0.isWhitespace }) {
                            paragraphContentBlocks.append(.paragraph(self._parseTextToRichText(text: tempText)))
                            tempText = Text()
                        }
                    }
                }

                for textFragment in text {
                    if case let .image(_, url, _) = textFragment, let url = url {
                        processTempText()
                        paragraphContentBlocks.append(.image(url: url))
                    } else if case let .link(text, url, _) = textFragment,
                              let url = url,
                              case let .text(t) = text[0],
                              t == ContentParser.magicStringLink {
                        processTempText()
                        paragraphContentBlocks.append(.linkPreview(url))
                    } else {
                        tempText.append(fragment: textFragment)
                    }
                }
                processTempText()
                return paragraphContentBlocks
            }
            return []
        case let .heading(level, text):
            return [.header(_parseTextToRichText(text: text), level)]
        case let .blockquote(blocks):
            return [.blockQuote(blocks.flatMap { _parse(block: $0) })]
        case .list:
            // All blocks are .listItem
            // .listItem's block could be:
            // 1. single paragraph
            // 2. A paragraph, with list(s) (When nested)
            if let list = _partList(block: block) {
                return [.list(list)]
            } else {
                return []
            }
        case .listItem:
            break
        case let .indentedCode(lines):
            return [.codeBlock(nil, lines.joined(separator: "\n"))]
        case let .fencedCode(fence, lines):
            return [.codeBlock(fence, lines.joined(separator: "\n"))]
        case let .htmlBlock(lines):
            // TODO: HTML is not supported in the web, so we will regard html block as a normal code block.
            return [.codeBlock(nil, lines.joined(separator: "\n"))]
        case .thematicBreak:
            return [.divider]
        case let .table(header, alignments, rows):
            break
        case let .custom(customBlock):
            // TODO: Custom blocks
            break
        }
        return []
    }

    private func extractContinuousImages(blocks: [ContentBlock]) -> [ContentBlock] {
        // Merge images and paragraphs
        var extractedBlocks: [ContentBlock] = []
        for block in blocks {
            if case let .image(currentUrl) = block {
                if let lastblock = extractedBlocks.last {
                    if case let .image(url) = lastblock {
                        _ = extractedBlocks.popLast()
                        let imagesContentBlock = ContentBlock.images(urls: [url, currentUrl])
                        extractedBlocks.append(imagesContentBlock)
                        continue
                    } else if case let .images(urls) = lastblock {
                        _ = extractedBlocks.popLast()
                        var newUrls: [String] = urls
                        newUrls.append(currentUrl)
                        let imagesContentBlock = ContentBlock.images(urls: newUrls)
                        extractedBlocks.append(imagesContentBlock)
                        continue
                    }
                }
            } else if case let .blockQuote(blocks) = block {
                extractedBlocks.append(.blockQuote(extractContinuousImages(blocks: blocks)))
                continue
            }

//             TODO: Header? This should be processed in attributed string level.
//            if case let .paragraph(richText) = block {
//                if let lastblock = finalContentBlocks.last {
//                    if case let .paragraph(lastRichText) = lastblock {
//                        _ = finalContentBlocks.popLast()
//                        let paragraphContentBlock = ContentBlock.paragraph(.concat([lastRichText, .plain("\n\n"), richText]))
//                        finalContentBlocks.append(paragraphContentBlock)
//                        continue
//                    }
//                }
//            }

            extractedBlocks.append(block)
        }
        return extractedBlocks
    }

    private func _parseBlocksToContentBlocks(blocks: Blocks) -> [ContentBlock] {
        let parsedBlocks = blocks.flatMap { _parse(block: $0) }
        return extractContinuousImages(blocks: parsedBlocks)
    }

    private func attributedStringForRichText(_ text: RichText, styleStack: ContentTextStyleStack) -> NSAttributedString {
        switch text {
        case .empty:
            return NSAttributedString(string: "", attributes: styleStack.textAttributes())
        case let .plain(string):
            let attributes = styleStack.textAttributes()
            return NSAttributedString(string: string, attributes: attributes)
        case let .bold(text):
            styleStack.push(.bold)
            let result = attributedStringForRichText(text, styleStack: styleStack)
            styleStack.pop()
            return result
        case let .italic(text):
            styleStack.push(.italic)
            let result = attributedStringForRichText(text, styleStack: styleStack)
            styleStack.pop()
            return result
        case let .underline(text):
            styleStack.push(.underline)
            let result = attributedStringForRichText(text, styleStack: styleStack)
            styleStack.pop()
            return result
        case let .strikethrough(text):
            styleStack.push(.strikethrough)
            let result = attributedStringForRichText(text, styleStack: styleStack)
            styleStack.pop()
            return result
        case let .link(text, url):
            styleStack.push(.textColor(.systemBlue))
            styleStack.push(.link(url))
            let result = attributedStringForRichText(text, styleStack: styleStack)
            styleStack.pop()
            styleStack.pop()
            return result
        case let .concat(texts):
            let string = NSMutableAttributedString()
            for text in texts {
                let substring = attributedStringForRichText(text, styleStack: styleStack)
                string.append(substring)
            }
            return string
        case let .subscript(text):
            styleStack.push(.subscript)
            let result = attributedStringForRichText(text, styleStack: styleStack)
            styleStack.pop()
            return result
        case let .superscript(text):
            styleStack.push(.superscript)
            let result = attributedStringForRichText(text, styleStack: styleStack)
            styleStack.pop()
            return result
        case let .marked(text):
            styleStack.push(.markerColor(.systemBlue))
            let result = attributedStringForRichText(text, styleStack: styleStack)
            styleStack.pop()
            return result
        case let .codeInline(codeString):
            styleStack.push(.markerColor(.systemGray))
            styleStack.push(.mono)
            let result = attributedStringForRichText(.plain(codeString), styleStack: styleStack)
            styleStack.pop()
            styleStack.pop()
            return result
        }
    }

    private func _parseContentBlocksToContentItems(contentBlocks: [ContentBlock]) -> [UIView] {
        var contentItems: [UIView] = []

        for contentBlock in contentBlocks {
            switch contentBlock {
            case let .paragraph(richText):
                let styleStack = ContentTextStyleStack()
                let attributedString = attributedStringForRichText(richText, styleStack: styleStack)
                contentItems.append(ContentItemParagraphUIView(attributedText: attributedString))
            case let .header(richText, level):
                let styleStack = ContentTextStyleStack()
                styleStack.push(.fontSize(-2.0 * CGFloat(level) + 30.0))
                styleStack.push(.bold)
                let attributedString = attributedStringForRichText(richText, styleStack: styleStack)
                contentItems.append(ContentItemParagraphUIView(attributedText: attributedString))
            case let .blockQuote(contentBlocks):
                let subContentItems = _parseContentBlocksToContentItems(contentBlocks: contentBlocks)
                if subContentItems.count > 0 {
                    contentItems.append(ContentItemBlockquoteUIView(contentItems: subContentItems))
                }
            case let .list(contentBlockList):
                break
            case .divider:
                contentItems.append(ContentItemDividerUIView())
            case let .codeBlock(optional, string):
                let attributes: [NSAttributedString.Key: Any] = [
                    NSAttributedString.Key.font: Font.monospace(17),
                    NSAttributedString.Key.foregroundColor: Asset.DynamicColors.dynamicBlack.color,
                ]
                let attributedString: NSAttributedString = .init(string: string, attributes: attributes)
                contentItems.append(ContentItemCodeBlockUIView(attributedText: attributedString))
            case let .linkPreview(link):
                if let url = URL(string: link) {
                    contentItems.append(ContentItemLinkPreview(link: url))
                }
            case let .image(url):
                if let url = URL(string: url) {
                    contentItems.append(ContentItemSingleImageUIView(url: url, onTapAction: {
                        ImageBrowser.shared.present(imageURLs: $1, selectedImageIndex: $0)
                    }))
                }
            case let .images(urls):
                let urls = urls.compactMap { URL(string: $0) }
                if urls.count > 0 {
                    contentItems.append(ContentItemImagesGridUIView(urls: urls, configuration: configuration))
                }
            case let .table(rows):
                break
            }
        }

        return contentItems
    }

    func parse() -> [UIView] {
        let markdown = MarkdownParser.standard.parse(content)
        guard case let .document(topLevelBlocks) = markdown else {
            return []
        }

        if contentBlocks == nil {
            contentBlocks = _parseBlocksToContentBlocks(blocks: topLevelBlocks)
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
            contentBlocks = _parseBlocksToContentBlocks(blocks: topLevelBlocks)
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

        let finalString = String(Array(textCharactersArray.prefix(maxIndex))).prefix(configuration.textLengthMax)

        return ContentExcerpt(text: String(finalString),
                              images: Array(images.prefix(configuration.imageCountMax)))
    }
}
