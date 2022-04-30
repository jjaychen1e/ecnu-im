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

class ContentItemBlockquoteUIView: UIView {
    private var contentItems: [UIView]
    private lazy var contentItemsUIView: PostContentItemsUIView = {
        let contentItemsUIView = PostContentItemsUIView(contentItems: contentItems)
        return contentItemsUIView
    }()

    private lazy var leftIndicator: UIView = {
        let indicator = UIView()
        indicator.backgroundColor = .blue.withAlphaComponent(0.3)
        return indicator
    }()

    init(contentItems: [UIView]) {
        self.contentItems = contentItems
        super.init(frame: .zero)
        
        if contentItems.count == 0 {
            snp.makeConstraints { make in
                make.height.equalTo(0.01)
            }
            return
        }

        addSubview(leftIndicator)
        leftIndicator.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(5)
        }

        addSubview(contentItemsUIView)
        contentItemsUIView.snp.makeConstraints { make in
            make.top.right.bottom.equalToSuperview()
            make.left.equalTo(leftIndicator.snp.right)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
