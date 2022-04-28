//
//  ContentBlock.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/25.
//

import Foundation

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
            return ""
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
