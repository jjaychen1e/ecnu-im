//
//  RichText.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/25.
//

import Foundation
import CoreGraphics
import MarkdownKit

public indirect enum RichTextType: Equatable {
    case empty
    case concat
    case plain
    case fontSize
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
    case fontSize(RichText, CGFloat)
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
        case let .fontSize(richText, _):
            return richText.plainText
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
        case let .fontSize(richText, fontSize):
            if case .fontSize(richText, fontSize) = rhs {
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

extension RichText {
    static func parseFrom(text: Text) -> RichText {
        var richTextArray: [RichText] = []
        for fragment in text {
            switch fragment {
            case let .text(text):
                richTextArray.append(.plain(String(text)))
            case let .code(text):
                richTextArray.append(.codeInline(String(text)))
            case let .emph(text):
                richTextArray.append(.italic(parseFrom(text: text)))
            case let .strong(text):
                richTextArray.append(.bold(parseFrom(text: text)))
            case let .link(text, url, _):
                if let url = url {
                    richTextArray.append(.link(text: parseFrom(text: text), url: url))
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

        while let last = richTextArray.last {
            if last.plainText == "\n" {
                richTextArray.removeLast()
            } else {
                break
            }
        }

        while let first = richTextArray.first {
            if first.plainText == "\n" {
                richTextArray.removeFirst()
            } else {
                break
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
    func attributedString(styleStack: ContentTextStyleStack) -> NSAttributedString {
        switch self {
        case .empty:
            return NSAttributedString(string: "", attributes: styleStack.textAttributes())
        case let .plain(string):
            let attributes = styleStack.textAttributes()
            return NSAttributedString(string: string, attributes: attributes)
        case let .fontSize(richText, fontSize):
            styleStack.push(.fontSize(fontSize))
            let result = richText.attributedString(styleStack: styleStack)
            styleStack.pop()
            return result
        case let .bold(text):
            styleStack.push(.bold)
            let result = text.attributedString(styleStack: styleStack)
            styleStack.pop()
            return result
        case let .italic(text):
            styleStack.push(.italic)
            let result = text.attributedString(styleStack: styleStack)
            styleStack.pop()
            return result
        case let .underline(text):
            styleStack.push(.underline)
            let result = text.attributedString(styleStack: styleStack)
            styleStack.pop()
            return result
        case let .strikethrough(text):
            styleStack.push(.strikethrough)
            let result = text.attributedString(styleStack: styleStack)
            styleStack.pop()
            return result
        case let .link(text, url):
            styleStack.push(.link(url))
            let result = text.attributedString(styleStack: styleStack)
            styleStack.pop()
            return result
        case let .concat(texts):
            let string = NSMutableAttributedString()
            for text in texts {
                let substring = text.attributedString(styleStack: styleStack)
                string.append(substring)
            }
            return string
        case let .subscript(text):
            styleStack.push(.subscript)
            let result = text.attributedString(styleStack: styleStack)
            styleStack.pop()
            return result
        case let .superscript(text):
            styleStack.push(.superscript)
            let result = text.attributedString(styleStack: styleStack)
            styleStack.pop()
            return result
        case let .marked(text):
            styleStack.push(.markerColor(.systemBlue))
            let result = text.attributedString(styleStack: styleStack)
            styleStack.pop()
            return result
        case let .codeInline(codeString):
            styleStack.push(.markerColor(.systemGray))
            styleStack.push(.mono)
            let result = RichText.plain(codeString).attributedString(styleStack: styleStack)
            styleStack.pop()
            styleStack.pop()
            return result
        }
    }
}
