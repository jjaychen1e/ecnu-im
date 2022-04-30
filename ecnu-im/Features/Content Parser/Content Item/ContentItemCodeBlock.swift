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

class ContentItemCodeBlockUIView: UIView {
    var attributedText: NSAttributedString
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        return textView
    }()

    init(attributedText: NSAttributedString) {
        self.attributedText = attributedText
        super.init(frame: .zero)
        textView.attributedText = attributedText
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
