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

class ContentItemDividerUIView: UIView {
    private lazy var dividerLineView: UIView = {
        let line = UIView()
        line.backgroundColor = .gray
        return line
    }()

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        snp.makeConstraints { make in
            make.height.equalTo(50)
        }

        addSubview(dividerLineView)
        dividerLineView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
