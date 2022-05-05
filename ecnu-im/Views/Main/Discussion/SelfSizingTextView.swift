//
//  SelfSizingTextView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/1.
//

import UIKit

class SelfSizingTextView: UITextView {
    private var preferredMaxLayoutWidth: CGFloat? {
        didSet {
            guard preferredMaxLayoutWidth != oldValue else { return }
            invalidateIntrinsicContentSize()
        }
    }

    override var attributedText: NSAttributedString! {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        guard let width = preferredMaxLayoutWidth else {
            return super.intrinsicContentSize
        }
        return CGSize(width: width, height: textHeightForWidth(width))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        preferredMaxLayoutWidth = bounds.width
    }
}

private extension UIEdgeInsets {
    var horizontal: CGFloat { return left + right }
    var vertical: CGFloat { return top + bottom }
}

private extension UITextView {
    func textHeightForWidth(_ width: CGFloat) -> CGFloat {
        let storage = NSTextStorage(attributedString: attributedText)
        let width = bounds.width - textContainerInset.horizontal
        let containerSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let container = NSTextContainer(size: containerSize)
        let manager = NSLayoutManager()
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        container.lineFragmentPadding = textContainer.lineFragmentPadding
        container.lineBreakMode = textContainer.lineBreakMode
        _ = manager.glyphRange(for: container)
        let usedHeight = manager.usedRect(for: container).height
        print(attributedText.string)
        print(usedHeight + textContainerInset.vertical)
        return ceil(usedHeight + textContainerInset.vertical)
    }
}
