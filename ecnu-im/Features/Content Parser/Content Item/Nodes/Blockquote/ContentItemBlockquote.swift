//
//  ContentItemBlockquote.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/28.
//

import Foundation
import SwiftUI

struct ContentItemBlockquote: View {
    @State var contentItems: [Any] = []

    var body: some View {
        PostContentItemsView(contentItems: $contentItems)
            .padding(.leading, 8)
            .background(
                HStack {
                    Color.blue.opacity(0.3)
                        .frame(width: 5)
                    Spacer()
                }
            )
    }
}

class ContentItemBlockquoteUIView: UIView & ContentBlockUIView {
    private var contentItems: [UIView]
    private lazy var contentItemsUIView: PostContentItemsUIView = {
        let contentItemsUIView = PostContentItemsUIView(contentItems: contentItems)
        return contentItemsUIView
    }()

    private lazy var leftIndicator: UIView = {
        let indicator = UIView()
        indicator.backgroundColor = try! UIColor(rgba_throws: "#6a737d")
        return indicator
    }()

    init(contentItems: [UIView]) {
        self.contentItems = contentItems
        super.init(frame: .zero)
        if contentItems.count == 0 {
            return
        }
        addSubview(leftIndicator)
        addSubview(contentItemsUIView)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        if contentItems.count == 0 {
            return CGSize(width: size.width, height: 0.01)
        }
        let contentItemsViewSize = contentItemsUIView.sizeThatFits(CGSize(width: size.width - 15, height: .greatestFiniteMagnitude))
        return CGSize(width: size.width, height: contentItemsViewSize.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if contentItems.count > 0 {
            let contentItemsViewSize = contentItemsUIView.sizeThatFits(CGSize(width: bounds.width - 15, height: .greatestFiniteMagnitude))
            leftIndicator.frame = CGRect(origin: .zero, size: CGSize(width: 5, height: contentItemsViewSize.height))
            contentItemsUIView.frame = CGRect(origin: .init(x: 15, y: 0), size: contentItemsViewSize)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
