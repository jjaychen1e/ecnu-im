//
//  RichText.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/25.
//

import Foundation

public indirect enum RichTextType: Equatable {
    case empty
    case concat
    case plain
    case bold
    case italic
    case underline
    case strikethrough
    case marked
    case codeInline
    case `subscript`
    case superscript
    case link
}

public indirect enum RichText {
    case empty
    case concat([RichText])
    case plain(String)
    case bold(RichText)
    case italic(RichText)
    case underline(RichText)
    case strikethrough(RichText)
    case marked(RichText)
    case codeInline(String)
    case `subscript`(RichText)
    case superscript(RichText)
    case link(text: RichText, url: String)

    var plainText: String {
        switch self {
        case .empty:
            return ""
        case let .concat(array):
            return array.map { $0.plainText }.joined()
        case let .plain(string):
            return string
        case let .bold(richText):
            return richText.plainText
        case let .italic(richText):
            return richText.plainText
        case let .underline(richText):
            return richText.plainText
        case let .strikethrough(richText):
            return richText.plainText
        case let .marked(richText):
            return richText.plainText
        case let .codeInline(string):
            return string
        case let .subscript(richText):
            return richText.plainText
        case let .superscript(richText):
            return richText.plainText
        case .link:
            return " [链接] "
        }
    }
}

extension RichText: Equatable {
    public static func == (lhs: RichText, rhs: RichText) -> Bool {
        switch lhs {
        case .empty:
            if case .empty = rhs {
                return true
            } else {
                return false
            }
        case let .concat(lhsTexts):
            if case let .concat(rhsTexts) = rhs, lhsTexts == rhsTexts {
                return true
            } else {
                return false
            }
        case let .plain(string):
            if case .plain(string) = rhs {
                return true
            } else {
                return false
            }
        case let .bold(text):
            if case .bold(text) = rhs {
                return true
            } else {
                return false
            }
        case let .italic(text):
            if case .italic(text) = rhs {
                return true
            } else {
                return false
            }
        case let .underline(text):
            if case .underline(text) = rhs {
                return true
            } else {
                return false
            }
        case let .strikethrough(text):
            if case .strikethrough(text) = rhs {
                return true
            } else {
                return false
            }
        case let .marked(text):
            if case .marked(text) = rhs {
                return true
            } else {
                return false
            }
        case let .codeInline(codeString):
            if case .codeInline(codeString) = rhs {
                return true
            } else {
                return false
            }
        case let .subscript(text):
            if case .subscript(text) = rhs {
                return true
            } else {
                return false
            }
        case let .superscript(text):
            if case .superscript(text) = rhs {
                return true
            } else {
                return false
            }
        case let .link(text, url):
            if case .link(text, url) = rhs {
                return true
            } else {
                return false
            }
        }
    }
}
