//
//  Editor.swift
//
//
//  Created by Quentin Eude on 10/03/2021.
//
import Combine

import UIKit

struct EditedText: Equatable {
    let string: String
    let editedRange: NSRange
}

public class Storage: NSTextStorage {
    public var theme: Theme? {
        didSet {
            beginEditing()
            applyStyles()
            endEditing()
        }
    }

    public var markdowner: (String, Int) -> [MarkdownNode] = { _, _ in [] }
    public var applyMarkdown: (MarkdownNode) -> [NSAttributedString.Key: Any] = { _ in [:] }
    public var applyBody: () -> [NSAttributedString.Key: Any] = { [:] }
    var cancellables = Set<AnyCancellable>()
    let subj = PassthroughSubject<EditedText, Never>()

    var backingStore = NSTextStorage()

    override public var string: String {
        return backingStore.string
    }

    override public init() {
        super.init()

        subj
            .removeDuplicates()
            .debounce(for: .milliseconds(0), scheduler: DispatchQueue.main)
            .sink(receiveValue: { s in
                self.beginEditing()
                print(s.editedRange)
                self.applyStyles(editedRange: s.editedRange)
                self.endEditing()
            })
            .store(in: &cancellables)
    }

    override public init(attributedString attrStr: NSAttributedString) {
        super.init(attributedString: attrStr)
        backingStore.setAttributedString(attrStr)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public required init(itemProviderData _: Data, typeIdentifier _: String) throws {
        fatalError("init(itemProviderData:typeIdentifier:) has not been implemented")
    }

    override public func attributes(
        at location: Int, longestEffectiveRange range: NSRangePointer?, in rangeLimit: NSRange
    ) -> [NSAttributedString.Key: Any] {
        return backingStore.attributes(at: location, longestEffectiveRange: range, in: rangeLimit)
    }

    override public func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        backingStore.replaceCharacters(in: range, with: str)
        let len = (str as NSString).length
        let change = len - range.length
        edited([.editedCharacters, .editedAttributes], range: range, changeInLength: change)
        endEditing()
    }

    override public func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        beginEditing()
        backingStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    override public func attributes(at location: Int, effectiveRange range: NSRangePointer?)
        -> [NSAttributedString.Key: Any] {
        return backingStore.attributes(at: location, effectiveRange: range)
    }

    override public func processEditing() {
        if editedMask != .editedAttributes {
            subj.send(EditedText(string: backingStore.string, editedRange: editedRange))
        }
        super.processEditing()
    }

    func applyStyles(editedRange: NSRange? = nil) {
        let paragraphNSRange = string.paragraph(for: editedRange)
        let paragraphRange = Range(paragraphNSRange, in: string)
        let paragraph: String
        if let paragraphRange = paragraphRange {
            paragraph = String(string[paragraphRange])
        } else {
            paragraph = string
        }
        let md = markdowner(paragraph, paragraphNSRange.lowerBound)
        setAttributes(applyBody(), range: paragraphNSRange)
        md.forEach {
            addAttributes(applyMarkdown($0), range: $0.range)
        }
        edited(.editedAttributes, range: paragraphNSRange, changeInLength: 0)
    }
}
