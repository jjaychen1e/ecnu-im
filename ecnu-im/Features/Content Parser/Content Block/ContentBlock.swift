//
//  ContentBlock.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/25.
//

import Foundation
import MarkdownKit
import Regex

indirect enum ContentBlockType: Equatable {
    case paragraph
    case header
    case blockQuote
    case list
    case divider
    case codeBlock
    case linkPreview
    case image
    case images
    case table
}

enum ContentTableItem: Equatable {}

struct ContentBlockList: Equatable {
    enum ContentListItem: Equatable {
        case text(RichText)
        case list(ContentBlockList)
    }

    enum ContentListType: Equatable {
        case bullet
        case ordered(Int)
    }

    var items: [ContentListItem]
    var listType: ContentListType
}

enum ContentBlock {
    case paragraph(RichText)
    case header(RichText, Int)
    case blockQuote([ContentBlock])
    case list(ContentBlockList)
    case divider
    case codeBlock(String?, String) // Language, Code
    case linkPreview(String)
    case image(url: String)
    case images(urls: [String])
    case table(rows: [ContentTableItem])

    var excerptText: String {
        switch self {
        case let .paragraph(richText):
            return richText.plainText
        case let .header(richText, _):
            return richText.plainText + " "
        case let .blockQuote(array):
            return array.map { $0.excerptText }.joined()
        case let .list(contentBlockList):
            return Self.excerptText(list: contentBlockList)
        case .divider:
            return ""
        case let .codeBlock(optional, content):
            return content
        case .linkPreview:
            return " [链接预览] "
        case .image:
            return ""
        case .images:
            return ""
        case let .table(rows):
            return ""
        }
    }

    private static func excerptText(list: ContentBlockList) -> String {
        var text = ""

        for (index, item) in list.items.enumerated() {
            let leadingCharacter: String = {
                switch list.listType {
                case .bullet:
                    return "\u{2022} "
                case let .ordered(number):
                    return "\(number + index). "
                }
            }()
            switch item {
            case let .text(richText):
                text.append(leadingCharacter)
                text.append(richText.plainText)
                text.append("\n")
            case let .list(contentBlockList):
                text.append(excerptText(list: contentBlockList))
            }
        }
        return text
    }
}

extension ContentBlock: Equatable {
    public static func == (lhs: ContentBlock, rhs: ContentBlock) -> Bool {
        switch lhs {
        case let .paragraph(text):
            if case .paragraph(text) = rhs {
                return true
            } else {
                return false
            }
        case let .header(text, level):
            if case .header(text, level) = rhs {
                return true
            } else {
                return false
            }
        case let .blockQuote(text):
            if case .blockQuote(text) = rhs {
                return true
            } else {
                return false
            }
        case let .list(list):
            if case .list(list) = rhs {
                return true
            } else {
                return false
            }
        case .divider:
            if case .divider = rhs {
                return true
            } else {
                return false
            }
        case let .codeBlock(lang, codeString):
            if case .codeBlock(lang, codeString) = rhs {
                return true
            } else {
                return false
            }
        case let .linkPreview(url):
            if case .linkPreview(url) = rhs {
                return true
            } else {
                return false
            }
        case let .image(url):
            if case .image(url) = rhs {
                return true
            } else {
                return false
            }
        case let .images(urls):
            if case .images(urls) = rhs {
                return true
            } else {
                return false
            }
        case let .table(rows):
            if case .table(rows) = rhs {
                return true
            } else {
                return false
            }
        }
    }
}

extension ContentBlock {
    private static let magicStringLink = "MagicStringLink-1650947"
    private static let magicStringImage = "MagicStringImage-1650947"

    static func parseFrom(block: Block) -> [ContentBlock] {
        switch block {
        case .document, .definitionList, .referenceDef:
            // TODO: Or, we need to parse them as normal text in case...
            break
        case let .paragraph(text):
            // A strong regex to match urls
            let content = processParagraph(content: text.description.trimmingCharacters(in: .newlines))
            let markdown = MarkdownParser.standard.parse(content)
            if case let .document(blocks) = markdown,
               blocks.count == 1,
               case let .paragraph(text) = blocks[0] {
                var paragraphContentBlocks: [ContentBlock] = []
                var tempText = Text()

                let processTempText = {
                    if tempText.count > 0 {
                        if let _ = tempText.rawDescription.first(where: { !$0.isWhitespace && !$0.isNewline }) {
                            paragraphContentBlocks.append(.paragraph(RichText.parseFrom(text: tempText)))
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
                              t == Self.magicStringLink {
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
            return [.header(RichText.parseFrom(text: text), level)]
        case let .blockquote(blocks):
            return [.blockQuote(blocks.flatMap { ContentBlock.parseFrom(block: $0) })]
        case .list:
            // All blocks are .listItem
            // .listItem's block could be:
            // 1. single paragraph
            // 2. A paragraph, with list(s) (When nested)
            if let list = parseList(block: block) {
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

    static func parseFrom(blocks: Blocks) -> [ContentBlock] {
        let parsedBlocks = blocks.flatMap { parseFrom(block: $0) }
        return extractContinuousImages(blocks: parsedBlocks)
    }

    /// Embed naked link and image url in `[]()` and `![]()`, and make all image urls and naked links in a single line.
    /// We embed all links inside `[]()`, and then re-extract those double embedded links.
    /// Next add `!` mark before all `.jp(e)g`, `.png` and `.gif` links.
    /// Finally, make all image urls and naked links in a single line.
    /// - Parameter content: original markdown content
    /// - Returns: processed markdown content
    private static func processParagraph(content: String) -> String {
        var content = content

        // A strong regex to match urls(and possible alt text)
        let _us = "(https?:\\/\\/)(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b([-a-zA-Z0-9()@:%_\\+.~#?&\\/\\/=]*)"

        // Remove possible alt text
        let markdownURLWithAltText = "\\[(.*?)\\]\\((\(_us))(\\s+.*?)?\\)"
        let _rMarkdownURL = try! Regex(string: "\(markdownURLWithAltText)", options: .ignoreCase)
        content = content.replacingAll(matching: _rMarkdownURL, with: "[$1]($2)")

        // All link ranges, in a reversed order
        let _rURL = try! Regex(string: "(\(_us))", options: .ignoreCase)
        let linkMatches = _rURL.allMatches(in: content).sorted(by: { $0.range.lowerBound > $1.range.lowerBound })

        let markdownURLWithAltText2 = "\\[.*?\\]\\((\(_us))(\\s+.*?)?\\)"
        let _rMarkdownURL2 = try! Regex(string: "\(markdownURLWithAltText2)", options: .ignoreCase)
        let markdownLinkMatches = _rMarkdownURL2.allMatches(in: content).sorted(by: { $0.range.lowerBound > $1.range.lowerBound })
        let markdownLinkCaptureRanges = markdownLinkMatches.compactMap { $0.captureRanges.first }.compactMap { $0 }
        let markdownLinkCaptureRangeLowerBounds = markdownLinkCaptureRanges.map { $0.lowerBound }

        for linkMatch in linkMatches {
            if !markdownLinkCaptureRangeLowerBounds.contains(linkMatch.range.lowerBound) {
                var isImage = false
                if let url = URL(string: linkMatch.matchedString),
                   let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                    let path = components.path
                    let _rImageSuffix = try! Regex(string: "\\.(png|jpe?g|gif)", options: .ignoreCase)
                    if _rImageSuffix.matches(path) {
                        isImage = true
                    }
                }
                content.replaceSubrange(linkMatch.range, with: "\(isImage ? "!" : "")[\(isImage ? Self.magicStringImage : Self.magicStringLink)](\(linkMatch.matchedString))")
            }
        }

        return content
    }

    private static func parseList(block: Block) -> ContentBlockList? {
        if case let .list(topListType, _, topBlocks) = block {
            var topListItems: [ContentBlockList.ContentListItem] = []
            for topBlock in topBlocks {
                if case let .listItem(_, _, subListBlocks) = topBlock {
                    for subListBlock in subListBlocks {
                        if case let .paragraph(text) = subListBlock {
                            topListItems.append(.text(RichText.parseFrom(text: text)))
                        } else if case .list = subListBlock, let list = parseList(block: subListBlock) {
                            topListItems.append(.list(list))
                        }
                    }
                }
            }
            return .init(items: topListItems, listType: topListType == nil ? .bullet : .ordered(topListType!))
        }
        return nil
    }

    private static func extractContinuousImages(blocks: [ContentBlock]) -> [ContentBlock] {
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
}
