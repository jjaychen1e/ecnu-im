//
//  ContentTextStyleStack.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/25.
//

import Foundation
import UIKit

enum ContentTextStyle {
    case bold
    case italic
    case underline
    case strikethrough
    case `subscript`
    case superscript
    case markerColor(UIColor)
    case linkColor(UIColor)
}

let ContentMarkerColorAttribute = "MarkerColorAttribute"

final class ContentTextStyleStack {
    private var items: [ContentTextStyle] = []

    func push(_ item: ContentTextStyle) {
        items.append(item)
    }

    func pop() {
        if !items.isEmpty {
            items.removeLast()
        }
    }

    func textAttributes() -> [NSAttributedString.Key: Any] {
        var bold: Bool?
        var italic: Bool?
        var strikethrough: Bool?
        var underline: Bool?
        var baselineOffset: CGFloat?
        var markerColor: UIColor?
        var linkColor: UIColor?

        for item in items.reversed() {
            switch item {
            case .bold:
                if bold == nil {
                    bold = true
                }
            case .italic:
                if italic == nil {
                    italic = true
                }
            case .strikethrough:
                if strikethrough == nil {
                    strikethrough = true
                }
            case .underline:
                if underline == nil {
                    underline = true
                }
            case .subscript:
                if baselineOffset == nil {
                    baselineOffset = 0.35
                    underline = false
                }
            case .superscript:
                if baselineOffset == nil {
                    baselineOffset = -0.35
                }
            case let .markerColor(color):
                if markerColor == nil {
                    markerColor = color
                }
            case let .linkColor(color):
                if linkColor == nil {
                    linkColor = color
                }
            }
        }

        var attributes: [NSAttributedString.Key: Any] = [:]

        var parsedFontSize = 16.0

        if let baselineOffset = baselineOffset {
            attributes[NSAttributedString.Key.baselineOffset] = round(parsedFontSize * baselineOffset)
            parsedFontSize = round(parsedFontSize * 0.85)
        }

        if bold != nil, bold!, italic != nil, italic! {
            attributes[NSAttributedString.Key.font] = Font.semiboldItalic(parsedFontSize)
        } else if bold != nil, bold! {
            attributes[NSAttributedString.Key.font] = Font.bold(parsedFontSize)
        } else if italic != nil, italic! {
            attributes[NSAttributedString.Key.font] = Font.italic(parsedFontSize)
        } else {
            attributes[NSAttributedString.Key.font] = Font.regular(parsedFontSize)
        }

        if strikethrough != nil, strikethrough! {
            attributes[NSAttributedString.Key.strikethroughStyle] = NSUnderlineStyle.single.rawValue as NSNumber
        }

        if underline != nil, underline! {
            attributes[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.single.rawValue as NSNumber
        }

        if let linkColor = linkColor {
            attributes[NSAttributedString.Key.foregroundColor] = linkColor
        } else {
            attributes[NSAttributedString.Key.foregroundColor] = UIColor.black
        }

        if let markerColor = markerColor {
            attributes[NSAttributedString.Key(rawValue: ContentMarkerColorAttribute)] = markerColor
        }

        return attributes
    }
}
