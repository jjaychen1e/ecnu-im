//
//  PostDeletedCell.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/30.
//

import UIKit

final class PostDeletedCell: UITableViewCell {
    static let identifier = "PostDeletedCell"
    
    private var label: UILabel!
    func configure() {}

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = DiscussionViewController.backgroundColor
        
        let label = UILabel()
        self.label = label
        label.text = "该楼层已被删除"
        label.textColor = Asset.DynamicColors.dynamicBlack.color.withAlphaComponent(0.5)
        label.textAlignment = .center
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
