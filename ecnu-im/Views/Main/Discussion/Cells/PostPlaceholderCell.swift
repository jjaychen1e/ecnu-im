//
//  PostPlaceholderCell.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/30.
//

import SwiftUI
import UIKit

private struct DiscussionViewPostCellPlaceholder: View {
    var body: some View {
        VStack {
            HStack {
                Circle()
                    .fill(Color(rgba: "#D6D6D6"))
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading) {
                    HStack {
                        Text("jjaychen")
                            .font(.system(size: 12, weight: .medium))
                        Text("1 分钟前")
                            .font(.system(size: 10, weight: .light))
                    }
                }
                Spacer()
            }
            Text(String(repeating: "那只敏捷的棕毛狐狸跳过那只懒狗，消失得无影无踪。", count: 10))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .redacted(reason: .placeholder)
    }
}

final class PostPlaceholderCell: UITableViewCell {
    static let identifier = "PostPlaceholderCell"
    private var hostingVC: UIHostingController<DiscussionViewPostCellPlaceholder>?

    func configure() {
        if hostingVC == nil {
            let hostingVC = UIHostingController(rootView: DiscussionViewPostCellPlaceholder(), ignoreSafeArea: true)
            self.hostingVC = hostingVC
            contentView.addSubview(hostingVC.view)
        }
    }

    let margin: CGFloat = 8.0

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = hostingVC?.view.systemLayoutSizeFitting(CGSize(width: bounds.width, height: .greatestFiniteMagnitude)) ?? .zero
        hostingVC?.view.frame = .init(origin: .init(x: 0, y: margin), size: size)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let s = hostingVC?.view.systemLayoutSizeFitting(CGSize(width: size.width, height: .greatestFiniteMagnitude)) ?? .zero
        return CGSize(width: s.width, height: s.height + margin * 2)
    }
}
