//
//  ContentParser.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/25.
//

import Foundation
import MarkdownKit
import Regex

class ContentParser {
    private var content: String = ""

    private let magicStringLink = "MagicStringLink-1650947"
    private let magicStringImage = "MagicStringImage-1650947"

    /// Embed naked link and image url in `[]()` and `![]()`, and make all image urls and naked links in a single line.
    /// We embed all links inside `[]()`, and then re-extract those double embedded links.
    /// Next add `!` mark before all `.jp(e)g`, `.png` and `.gif` links.
    /// Finally, make all image urls and naked links in a single line.
    /// - Parameter content: original markdown content
    /// - Returns: processed markdown content
    private func preprocess(content: String) -> String {
        // A strong regex to match urls
        let _us = "(https?:\\/\\/)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b([-a-zA-Z0-9()@:%_\\+.~#?&\\/\\/=]*)"
        let _r1 = try! Regex(string: "(\(_us))", options: .ignoreCase)
        var content = content.replacingAll(matching: _r1, with: "[\(magicStringLink)]($1)")

        let _r2 = try! Regex(string: "\\[(.*?)\\]\\(\\[\(magicStringLink)\\]\\((.*?)\\)\\)", options: .ignoreCase)
        content = content.replacingAll(matching: _r2, with: "[$1]($2)")

        let _r3 = try! Regex(string: "\\[\(magicStringLink)\\]\\((\(_us)\\.(png|jpe?g|gif))\\)", options: .ignoreCase)
        content = content.replacingAll(matching: _r3, with: "![\(magicStringImage)]($1)")

        let _r4 = try! Regex(string: "(!\\[.*?\\]\\(\(_us)\\.(png|jpe?g|gif)\\))", options: .ignoreCase)
        content = content.replacingAll(matching: _r4, with: "\n\n$1\n\n")

        let _r5 = try! Regex(string: "(\\[\(magicStringLink)\\]\\(.*?\\))", options: .ignoreCase)
        content = content.replacingAll(matching: _r5, with: "\n\n$1\n\n")

        return content
    }

    init(content: String) {
        self.content = preprocess(content: content)
    }

    private func _parseToRichText(text: Text) -> RichText {
        var richTextArray: [RichText] = []
        for fragment in text {
            switch fragment {
            case let .text(text):
                richTextArray.append(.plain(String(text)))
            case let .code(text):
                richTextArray.append(.codeInline(String(text)))
            case let .emph(text):
                richTextArray.append(.italic(_parseToRichText(text: text)))
            case let .strong(text):
                richTextArray.append(.bold(_parseToRichText(text: text)))
            case let .link(text, url, _):
                if let url = url {
                    richTextArray.append(.link(text: _parseToRichText(text: text), url: url))
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
                            topListItems.append(.text(_parseToRichText(text: text)))
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

    private func _parse(block: Block) -> ContentBlock? {
        switch block {
        case .document, .definitionList, .referenceDef:
            // TODO: Or, we need to parse them as normal text in case...
            break
        case let .paragraph(text):
            if text.count == 1 {
                if case let .image(_, url, _) = text[0], let url = url {
                    return .image(url: url)
                } else if case let .link(text, url, _) = text[0],
                          let url = url,
                            case let .text(t) = text[0],
                          t == magicStringLink {
                    return .linkPreview(url)
                }
            }
            return .paragraph(_parseToRichText(text: text))
        case let .heading(level, text):
            return .header(_parseToRichText(text: text), level)
        case let .blockquote(blocks):
            return .blockQuote(blocks.compactMap { _parse(block: $0) })
        case .list:
            // All blocks are .listItem
            // .listItem's block could be:
            // 1. single paragraph
            // 2. A paragraph, with list(s) (When nested)
            if let list = _partList(block: block) {
                return .list(list)
            } else {
                return nil
            }
        case .listItem:
            break
        case let .indentedCode(lines):
            return .codeBlock(nil, lines.joined(separator: "\n"))
        case let .fencedCode(fence, lines):
            return .codeBlock(fence, lines.joined(separator: "\n"))
        case let .htmlBlock(lines):
            // TODO: HTML is not supported in the web, so we will regard html block as a normal code block.
            return .codeBlock(nil, lines.joined(separator: "\n"))
        case .thematicBreak:
            return .divider
        case let .table(header, alignments, rows):
            break
        case let .custom(customBlock):
            // TODO: Custom blocks
            break
        }
        return nil
    }

    func parse() -> [ContentBlock] {
        let markdown = MarkdownParser.standard.parse(content)
        guard case let .document(topLevelBlocks) = markdown else {
            return []
        }

//        for block in topLevelBlocks {
//            print(block)
//        }

        let parsedBlocks = topLevelBlocks.compactMap { _parse(block: $0) }

        // Merge images
        var finalContentBlocks: [ContentBlock] = []
        for parsedBlock in parsedBlocks {
            if case let .image(currentUrl) = parsedBlock {
                if let lastParsedBlock = finalContentBlocks.last {
                   if case let .image(url) = lastParsedBlock {
                       _ = finalContentBlocks.popLast()
                       let imagesContentBlock = ContentBlock.images(urls: [url, currentUrl])
                       finalContentBlocks.append(imagesContentBlock)
                       continue
                   } else if case let .images(urls) = lastParsedBlock {
                       _ = finalContentBlocks.popLast()
                       var newUrls: [String] = urls
                       newUrls.append(currentUrl)
                       let imagesContentBlock = ContentBlock.images(urls: newUrls)
                       finalContentBlocks.append(imagesContentBlock)
                       continue
                   }
                }
            }

            finalContentBlocks.append(parsedBlock)
        }

        return finalContentBlocks
    }
}
