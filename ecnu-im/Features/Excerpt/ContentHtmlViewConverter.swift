//
//  ContentHtmlViewConverter.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/27.
//

import Foundation
import Kingfisher
import SwiftSoup
import SwiftUI

enum ContentHtmlViewConverterMode {
    case normal
    case excerpt
}

enum SpecialContentType {
    case linkPeview(link: String)
    case image(src: String)
}

class ContentHtmlViewConverter {
    private let mode: ContentHtmlViewConverterMode
    private var textLength = 0
    private var linkPreviewCount = 0
    private let elementCountLimit: Int
    private let textLengthLimit: Int
    private(set) var images: [String] = []

    var allowedTextLength: Int {
        max(0, textLengthLimit - textLength)
    }

    init(elementCountLimit: Int = Int.max, textLengthLimit: Int = Int.max, mode: ContentHtmlViewConverterMode = .normal) {
        self.elementCountLimit = elementCountLimit
        self.textLengthLimit = textLengthLimit
        self.mode = mode
    }

    func convert(_ elements: Elements) -> [Any] {
        let views = converViews(elements)
        textLength = 0
        linkPreviewCount = 0

        return views
    }

    private func converViews(_ elements: Elements) -> [Any] {
        var views: [Any] = []
        for element in elements {
            views.append(contentsOf: convertViewHierachy(element))
        }
        return views
    }

    private func convertViewHierachy(_ element: Element) -> [Any] {
        if textLength > textLengthLimit {
            return []
        } else {
            if element.children().count == 0 {
                return convertSingleElement(element: element)
            } else {
                // Child nodes...
                if element.tagName() == "p" {
                    return convertElementP(element: element)
                } else if element.tagName() == "ul" {
                    return convertList(type: .unordered, element: element, level: 0)
                } else if element.tagName() == "ol" {
                    return convertList(type: .ordered, element: element, level: 0)
                } else if element.tagName() == "blockquote" {
                    return convertElementBlockquote(element: element)
                }
            }
        }

        return []
    }
}

extension ContentHtmlViewConverter {
    private func convertText(element: Element) -> Text? {
        if let text = try? element.text() {
            let extractedText = text.trimmingCharacters(in: .whitespaces).prefix(allowedTextLength)
            if extractedText != "" {
                textLength += extractedText.count
                return Text(extractedText)
            }
        }
        return nil
    }

    private func convertHeading(element: Element, headingLevel: Int = 0) -> Text? {
        if let text = try? element.text() {
            let extractedText = text.trimmingCharacters(in: .whitespaces).prefix(allowedTextLength)
            if extractedText != "" {
                textLength += extractedText.count
                var fontSize: CGFloat = mode == .excerpt ? 10 : 12
                if headingLevel == 1 {
                    fontSize = mode == .excerpt ? 20 : 28
                } else if headingLevel == 2 {
                    fontSize = mode == .excerpt ? 18 : 24
                } else if headingLevel == 3 {
                    fontSize = mode == .excerpt ? 16 : 20
                } else if headingLevel == 4 {
                    fontSize = mode == .excerpt ? 14 : 16
                } else if headingLevel == 5 {
                    fontSize = mode == .excerpt ? 12 : 14
                } else if headingLevel == 6 {
                    fontSize = mode == .excerpt ? 10 : 12
                }

                return Text(extractedText)
                    .font(.system(size: fontSize, weight: .bold))
            }
        }

        return nil
    }

    private func convertImage(url: String) -> some View {
        KFImage.url(URL(string: url))
            .placeholder {
                ProgressView()
            }
            .loadDiskFileSynchronously()
            .cancelOnDisappear(true)
            .fade(duration: 0.25)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    private func convertSingleElement(element: Element) -> [Any] {
        if element.tagName() == "p" {
            if let singleViewResult = convertText(element: element) {
                return [singleViewResult]
            } else {
                return []
            }
        }

        if element.tagName() == "h1" {
            if let singleViewResult = convertHeading(element: element, headingLevel: 1) {
                return [singleViewResult]
            } else {
                return []
            }
        }

        if element.tagName() == "h2" {
            if let singleViewResult = convertHeading(element: element, headingLevel: 2) {
                return [singleViewResult]
            } else {
                return []
            }
        }

        if element.tagName() == "h3" {
            if let singleViewResult = convertHeading(element: element, headingLevel: 3) {
                return [singleViewResult]
            } else {
                return []
            }
        }

        if element.tagName() == "h4" {
            if let singleViewResult = convertHeading(element: element, headingLevel: 4) {
                return [singleViewResult]
            } else {
                return []
            }
        }

        if element.tagName() == "h5" {
            if let singleViewResult = convertHeading(element: element, headingLevel: 5) {
                return [singleViewResult]
            } else {
                return []
            }
        }

        if element.tagName() == "h6" {
            if let singleViewResult = convertHeading(element: element, headingLevel: 6) {
                return [singleViewResult]
            } else {
                return []
            }
        }

        if element.tagName() == "img" {
            if var src = try? element.attr("src") {
                if !src.hasPrefix("http://"), !src.hasPrefix("https://") {
                    print("Add prefix: \(src)")
                    src = flarumBaseURL + src
                }
                images.append(src)

//                        if mode == .normal {
                return [convertImage(url: src)]
//                        }
            }
        }

        return []
    }

    private func convertElementBlockquote(element: Element) -> [Any] {
        return convertElementP(element: element.child(0).child(0))
    }

    private func convertElementP(element: Element) -> [Any] {
        var components: [Any] = []
        for node in element.getChildNodes() {
            if let elementNode = node as? Element {
                if elementNode.tagName() == "strong" {
                    if let text = try? elementNode.text() {
                        let extractedText = text.trimmingCharacters(in: .whitespaces).prefix(allowedTextLength)
                        if extractedText != "" {
                            components.append(Text(extractedText).bold())
                            textLength += extractedText.count
                        }
                    }
                }

                if elementNode.tagName() == "em" {
                    if let text = try? elementNode.text() {
                        let extractedText = text.trimmingCharacters(in: .whitespaces).prefix(allowedTextLength)
                        if extractedText != "" {
                            components.append(Text(extractedText).italic())
                            textLength += extractedText.count
                        }
                    }
                }

                if elementNode.tagName() == "del" {
                    if let text = try? elementNode.text() {
                        let extractedText = text.trimmingCharacters(in: .whitespaces).prefix(allowedTextLength)
                        if extractedText != "" {
                            components.append(Text(extractedText).strikethrough())
                            textLength += extractedText.count
                        }
                    }
                }

                if elementNode.tagName() == "br" {
                    if allowedTextLength > 0 {
                        components.append("\n")
                    }
                }

                if elementNode.tagName() == "a" {
                    if elementNode.children().count == 0 {
                        if let href = try? elementNode.attr("href") {
                            if let text = try? elementNode.text() {
                                if href == text {
                                    // Link Prewview
                                    // We need to break down the texts, and show a link prewview
                                    components.append(SpecialContentType.linkPeview(link: href))
                                } else {
                                    if let classNames = try? elementNode.classNames(),
                                       classNames.contains("PostMention") {
                                        // e.g., @jjaychen
                                        var attributedString = try! AttributedString(markdown: "[@\(text) ](\(href))")
                                        attributedString.foregroundColor = ThemeManager.shared.theme.mentionColor
                                        components.append(
                                            Text(attributedString)
                                                .bold()
                                        )
                                        textLength += text.count
                                    } else {
                                        // Normal Markdown Link
                                        // If this is outside link, open it in browser
                                        // If this is a ecnu.im link, we need to navigate to a new view
                                        var attributedString = try! AttributedString(markdown: "[\(text)](\(href))")
                                        attributedString.foregroundColor = ThemeManager.shared.theme.linkTextColor
                                        components.append(Text(attributedString))
                                        textLength += text.count
                                    }
                                }
                            }
                        }

                    } else {
                        // May be an image
                        let children = elementNode.children()
                        if children.count == 1,
                           children[0].tagName() == "img",
                           let src = try? children[0].attr("src") {
                            components.append(SpecialContentType.image(src: src))
                        }
                    }
                }
            } else if let textNode = node as? TextNode {
                // A normal text node
                let text = textNode.text()
                let extractedText = text.trimmingCharacters(in: .whitespaces).prefix(allowedTextLength)
                if extractedText != "" {
                    components.append(Text(extractedText))
                }
                textLength += extractedText.count
            } else {
                print("Unknown node type.")
            }
        }

        var views: [Any] = []
        var accumulatedText: Text?

        var index = 0
        while index < components.count {
            defer {
                index += 1
            }
            let component = components[index]
            if let text = component as? Text {
                if accumulatedText == nil {
                    accumulatedText = text
                } else {
                    accumulatedText = accumulatedText! + text
                }
            } else if let str = component as? String {
                if str == "\n" {
                    if accumulatedText != nil {
                        views.append(accumulatedText!)
                        accumulatedText = nil
                    }
                }
            } else if case let SpecialContentType.linkPeview(link) = component {
                if mode == .excerpt, linkPreviewCount >= 1 {
                    continue
                }
                linkPreviewCount += 1
                views.append(AnyView(LinkPreviewView(link: link).frame(maxWidth: 400)))
            } else if case let SpecialContentType.image(src) = component {
                var images = [URL(string: src)]
                index += 1
                while index < components.count {
                    if case let SpecialContentType.image(src) = components[index] {
                        images.append(URL(string: src))
                    } else if let str = components[index] as? String, str == "\n" {
                        // This is ok.
                    } else {
                        break
                    }
                    index += 1
                }
                index -= 1

                views.append(images)
            }
        }
        if accumulatedText != nil {
            views.append(accumulatedText!)
        }

        return views
    }

    private enum ListType {
        case unordered
        case ordered
    }

    private func convertLI(nodes: [Node], type: ListType, level: Int, index: Int) -> [Any] {
        let prefixWhitespaces = String(repeating: "\t", count: level)
        var views: [Any] = []
        var standAloneText: Text?
        for textOrNode in nodes {
            if let elementNode = textOrNode as? Element {
                if elementNode.tagName() == "p" {
                    views.append(contentsOf: convertElementP(element: elementNode))
                } else if elementNode.tagName() == "ul" {
                    views.append(contentsOf: convertList(type: .unordered, element: elementNode, level: level + 1))
                } else if elementNode.tagName() == "ol" {
                    views.append(contentsOf: convertList(type: .ordered, element: elementNode, level: level + 1))
                } else if elementNode.tagName() == "a" {
                    views.append(contentsOf: convertElementP(element: elementNode.parent()!))
                } else if ["strong", "em", "del"].contains(elementNode.tagName()) {
                    if elementNode.tagName() == "strong" {
                        if let text = try? elementNode.text() {
                            let extractedText = text.trimmingCharacters(in: .whitespaces).prefix(allowedTextLength)
                            if extractedText != "" {
                                if standAloneText != nil {
                                    standAloneText = standAloneText! + Text(extractedText).bold()
                                } else {
                                    standAloneText = Text(extractedText).bold()
                                }
                                textLength += extractedText.count
                            }
                        }
                    }

                    if elementNode.tagName() == "em" {
                        if let text = try? elementNode.text() {
                            let extractedText = text.trimmingCharacters(in: .whitespaces).prefix(allowedTextLength)
                            if extractedText != "" {
                                if standAloneText != nil {
                                    standAloneText = standAloneText! + Text(extractedText).italic()
                                } else {
                                    standAloneText = Text(extractedText).italic()
                                }
                                textLength += extractedText.count
                            }
                        }
                    }

                    if elementNode.tagName() == "del" {
                        if let text = try? elementNode.text() {
                            let extractedText = text.trimmingCharacters(in: .whitespaces).prefix(allowedTextLength)
                            if extractedText != "" {
                                if standAloneText != nil {
                                    standAloneText = standAloneText! + Text(extractedText).strikethrough()
                                } else {
                                    standAloneText = Text(extractedText).strikethrough()
                                }
                                textLength += extractedText.count
                            }
                        }
                    }
                }
            } else if let textNode = textOrNode as? TextNode {
                // Pure text
                let text = textNode.text()
                let extractedText = text.trimmingCharacters(in: .whitespaces).prefix(allowedTextLength)
                if extractedText != "" {
                    if standAloneText != nil {
                        standAloneText = standAloneText! + Text(extractedText)
                    } else {
                        standAloneText = Text(extractedText)
                    }
                    textLength += extractedText.count
                }
            }
        }

        let prefixText = type == .unordered ? Text(prefixWhitespaces + "• ") : Text(prefixWhitespaces + "\(index + 1). ")

        if standAloneText != nil {
            views.insert(prefixText + standAloneText!, at: 0)
        } else if let textView = views.first as? Text {
            views[0] = prefixText + textView
        }

        return views
    }

    private func convertList(type: ListType, element: Element, level: Int) -> [Any] {
        var views: [Any] = []
        var index = 0
        for node in element.children() {
            if node.tagName() == "li" {
                views.append(contentsOf: convertLI(nodes: node.getChildNodes(), type: type, level: level, index: index))
                index += 1
            }
        }
        return views
    }
}
