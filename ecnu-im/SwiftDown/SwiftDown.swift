//
//  SwiftDown.swift
//
//
//  Created by Quentin Eude on 16/03/2021.
//

import UIKit

// MARK: - SwiftDown iOS

public class SwiftDown: UITextView, UITextViewDelegate {
    var storage: Storage = .init()

    convenience init(frame: CGRect, theme: Theme) {
        self.init(frame: frame, textContainer: nil)
        storage.theme = theme
        backgroundColor = theme.backgroundColor
        tintColor = theme.tintColor
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    override init(frame: CGRect, textContainer _: NSTextContainer?) {
        let layoutManager = NSLayoutManager()
        let containerSize = CGSize(width: frame.size.width, height: frame.size.height)
        let container = NSTextContainer(size: containerSize)
        container.widthTracksTextView = true

        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)
        super.init(frame: frame, textContainer: container)
        delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let layoutManager = NSLayoutManager()
        let containerSize = CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude)
        let container = NSTextContainer(size: containerSize)
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)
        delegate = self
    }
}
