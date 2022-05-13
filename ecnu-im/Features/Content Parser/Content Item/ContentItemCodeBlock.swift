//
//  ContentItemCodeBlock.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/28.
//

import SwiftUI
import UIKit

struct ContentItemCodeBlock: View {
    @State var text: NSAttributedString
    @State var textHeight: CGFloat = 0

    var body: some View {
        DynamicHeightTextView(text: $text, height: $textHeight)
            .frame(height: textHeight)
            .padding(.all, 4)
            .background(Color.primary.opacity(0.1))
    }
}

class ContentItemCodeBlockUIView: UIView & ContentBlockUIView {
    var attributedText: NSAttributedString
    private lazy var textView: ECNUTextView = {
        let textView = ECNUTextView()
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isEditable = false
        textView.isScrollEnabled = false
        return textView
    }()

    init(attributedText: NSAttributedString) {
        self.attributedText = attributedText
        super.init(frame: .zero)
        textView.attributedText = attributedText
        addSubview(textView)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard size.width > 0 else { return .zero }
        return CGSize(width: size.width, height: textView.sizeThatFits(frame.size).height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = textView.sizeThatFits(bounds.size)
        textView.backgroundColor = .clear
        textView.frame = .init(origin: .zero, size: size)
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        return .init(width: bounds.width, height: textView.frame.size.height)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
