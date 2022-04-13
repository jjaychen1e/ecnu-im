//
//  File.swift
//
//
//  Created by Quentin Eude on 16/03/2021.
//

import SwiftUI

// MARK: - SwiftDownEditor iOS

public struct SwiftDownEditor: UIViewRepresentable {
    @Binding var text: String

    private(set) var isEditable: Bool = true
    private(set) var theme: Theme = Theme.BuiltIn.defaultDark.theme()
    private(set) var insetsSize: CGFloat = 0
    private(set) var autocapitalizationType: UITextAutocapitalizationType = .sentences
    private(set) var autocorrectionType: UITextAutocorrectionType = .default
    private(set) var keyboardType: UIKeyboardType = .default
    private(set) var textAlignment: TextAlignment = .leading

    public var onTextChange: (String) -> Void = { _ in }
    let engine = MarkdownEngine()

    public init(
        text: Binding<String>,
        onTextChange: @escaping (String) -> Void = { _ in }
    ) {
        _text = text
        self.onTextChange = onTextChange
    }

    public func makeUIView(context: Context) -> UITextView {
        let swiftDown = SwiftDown(frame: .zero, theme: theme)
        swiftDown.delegate = context.coordinator
        swiftDown.text = text
        swiftDown.isEditable = isEditable
        swiftDown.isScrollEnabled = true
        swiftDown.keyboardType = keyboardType
        swiftDown.autocapitalizationType = autocapitalizationType
        swiftDown.autocorrectionType = autocorrectionType
        swiftDown.textContainerInset = UIEdgeInsets(
            top: insetsSize, left: insetsSize, bottom: insetsSize, right: insetsSize
        )
        swiftDown.backgroundColor = theme.backgroundColor
        swiftDown.tintColor = theme.tintColor
        swiftDown.textColor = theme.tintColor
        swiftDown.storage.markdowner = { self.engine.render($0, offset: $1) }
        swiftDown.storage.applyMarkdown = { m in Theme.applyMarkdown(markdown: m, with: self.theme) }
        swiftDown.storage.applyBody = { Theme.applyBody(with: self.theme) }
        return swiftDown
    }

    public func updateUIView(_: UITextView, context _: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// MARK: - SwiftDownEditor iOS Coordinator

public extension SwiftDownEditor {
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SwiftDownEditor

        init(_ parent: SwiftDownEditor) {
            self.parent = parent
        }

        public func textViewDidChange(_ textView: UITextView) {
            guard textView.markedTextRange == nil else { return }

            parent.text = textView.text
        }
    }
}

// MARK: - iOS Specifics modifiers

public extension SwiftDownEditor {
    func autocapitalizationType(_ type: UITextAutocapitalizationType) -> Self {
        var new = self
        new.autocapitalizationType = type
        return new
    }

    func autocorrectionType(_ type: UITextAutocorrectionType) -> Self {
        var new = self
        new.autocorrectionType = type
        return new
    }

    func keyboardType(_ type: UIKeyboardType) -> Self {
        var new = self
        new.keyboardType = type
        return new
    }

    func textAlignment(_ type: TextAlignment) -> Self {
        var new = self
        new.textAlignment = type
        return new
    }
}

// MARK: - Common Modifiers

public extension SwiftDownEditor {
    func insetsSize(_ size: CGFloat) -> Self {
        var editor = self
        editor.insetsSize = size
        return editor
    }

    func theme(_ theme: Theme) -> Self {
        var editor = self
        editor.theme = theme
        return editor
    }

    func isEditable(_: Bool) -> Self {
        var editor = self
        editor.isEditable = true
        return editor
    }
}
