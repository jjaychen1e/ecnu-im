//
//  ContentItemParagraph.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/28.
//

import Foundation
import SwiftUI

struct ContentItemParagraph: View {
    @State var text: NSAttributedString
    @State var textHeight: CGFloat = 0

    var body: some View {
        DynamicHeightTextView(text: $text, height: $textHeight)
            .frame(height: textHeight)
    }
}

class ContentItemParagraphUIView: UIView & ContentBlockUIView {
    var attributedText: NSAttributedString
    private lazy var textView: ECNUTextView = {
        let textView = ECNUTextView()
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.contentInset = .zero
        textView.isEditable = false
        textView.isScrollEnabled = false
        return textView
    }()

    init(attributedText: NSAttributedString) {
        self.attributedText = attributedText
        super.init(frame: .zero)
        textView.backgroundColor = .clear
        textView.attributedText = attributedText
        textView.textContainerInset = .zero
        addSubview(textView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard size.width > 0 else { return .zero }
        return CGSize(width: size.width, height: textView.sizeThatFits(size).height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = textView.sizeThatFits(bounds.size)
        textView.frame = .init(origin: .zero, size: size)
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        return .init(width: bounds.width, height: textView.frame.size.height)
    }
}
