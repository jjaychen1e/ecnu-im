//
//  ContentItemDivider.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/28.
//

import SwiftUI

struct ContentItemDivider: View {
    var body: some View {
        Color.gray
            .frame(height: 1)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
    }
}

class ContentItemDividerUIView: UIView & ContentBlockUIView {
    private lazy var dividerLineView: UIView = {
        let line = UIView()
        line.backgroundColor = .gray
        return line
    }()

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        addSubview(dividerLineView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: 50)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        dividerLineView.frame = .init(origin: .init(x: 0, y: 24.5), size: .init(width: bounds.width, height: 1))
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        return .init(width: bounds.width, height: 50)
    }
}
