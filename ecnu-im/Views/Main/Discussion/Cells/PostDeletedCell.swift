//
//  PostDeletedCell.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/30.
//

import UIKit

final class PostDeletedCell: UITableViewCell {
    static let identifier = "PostDeletedCell"
    func configure() {}

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = DiscussionViewController.backgroundColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        frame = .init(origin: .zero, size: .init(width: bounds.width, height: 0.01))
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: 0.01)
    }
}
