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
        textView.isEditable = false
        textView.isScrollEnabled = false
        return textView
    }()

    init(attributedText: NSAttributedString) {
        self.attributedText = attributedText
        super.init(frame: .zero)
        textView.attributedText = attributedText
        textView.delegate = self
        layer.borderWidth = 1.0
        layer.borderColor = Asset.DynamicColors.dynamicBlack.color.withAlphaComponent(0.5).cgColor
        layer.cornerRadius = 4
        backgroundColor = .secondarySystemBackground
        clipsToBounds = true
        addSubview(textView)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard size.width > 0 else { return .zero }
        return CGSize(width: size.width, height: textView.sizeThatFits(size).height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = textView.sizeThatFits(bounds.size)
        textView.frame = .init(origin: .zero, size: size)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ContentItemCodeBlockUIView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if url.absoluteString.hasPrefix(URLService.scheme) {
            // Our scheme
            UIApplication.shared.open(url)
        } else {
            // As a normal link
            if let url = URLService.link(href: url.absoluteString).url.url {
                UIApplication.shared.open(url)
            }
        }
        return true
    }
}
