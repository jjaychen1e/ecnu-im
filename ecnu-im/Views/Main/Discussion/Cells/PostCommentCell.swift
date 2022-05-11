//
//  PostCommentCell.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/30.
//

import FlexLayout
import PinLayout
import SnapKit
import SwiftUI
import SwiftyJSON
import UIKit

final class PostCommentCell: UITableViewCell {
    static let identifier = "PostCommentCell"
    private var post: FlarumPost?
    private var postContentItemsUIView: PostContentItemsUIView?
    private var headerViewHostingVC = UIHostingController(rootView: PostCommentCellHeaderView(post: .init(id: "")), ignoreSafeArea: true)
    private var footerViewHostingVC = UIHostingController(rootView: PostCommentCellFooterView(post: .init(id: ""), replyAction: {}), ignoreSafeArea: true)

    private let avatarViewSize: CGFloat = 40.0
    private let avatarContentMargin: CGFloat = 8.0
    private let contentVerticalSpacing: CGFloat = 4.0
    private var margin: UIEdgeInsets {
        DiscussionViewController.margin
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        headerViewHostingVC.view.backgroundColor = .clear
        contentView.addSubview(headerViewHostingVC.view)

        footerViewHostingVC.view.backgroundColor = .clear
        contentView.addSubview(footerViewHostingVC.view)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(post: FlarumPost, updateLayout: (() -> Void)?) {
        if post != self.post {
            self.post = post
            postContentItemsUIView?.removeFromSuperview()

            if let content = post.attributes?.content, case let .comment(comment) = content {
                let parseConfiguration = ParseConfiguration(imageOnTapAction: { ImageBrowser.shared.present(imageURLs: $1, selectedImageIndex: $0) },
                                                            imageGridDisplayMode: .narrow)
                let contentParser = ContentParser(content: comment, configuration: parseConfiguration, updateLayout: updateLayout)
                let newContentItems = contentParser.parse()
                let postContentItemsUIView = PostContentItemsUIView(contentItems: newContentItems)
                self.postContentItemsUIView = postContentItemsUIView
                contentView.addSubview(postContentItemsUIView)
            } else {
                let attributedString = NSAttributedString(string: "无法查看预览内容，请检查账号邮箱是否已验证。")
                let postContentItemsUIView = PostContentItemsUIView(contentItems: [ContentItemParagraphUIView(attributedText: attributedString)])
                self.postContentItemsUIView = postContentItemsUIView
                contentView.addSubview(postContentItemsUIView)
            }

            headerViewHostingVC.rootView.update(post: post)
            footerViewHostingVC.rootView.update(post: post, replyAction: {})
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }

    private func layout() {
        if let postContentItemsUIView = postContentItemsUIView {
            headerViewHostingVC.view.pin.top(margin.top).left(margin.left).right(margin.right).sizeToFit(.width)
            postContentItemsUIView.pin.below(of: headerViewHostingVC.view, aligned: .left).marginTop(contentVerticalSpacing).right(margin.right).sizeToFit(.width)
            footerViewHostingVC.view.pin.below(of: [postContentItemsUIView], aligned: .left).marginTop(contentVerticalSpacing).right(margin.right).sizeToFit(.width)
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        if let postContentItemsUIView = postContentItemsUIView {
            contentView.pin.width(size.width)

            let availableWidth = max(size.width - margin.left - margin.right, 0)
            let targetSize = CGSize(width: availableWidth,
                                    height: .greatestFiniteMagnitude)

            let headerHeight = headerViewHostingVC.sizeThatFits(in: targetSize).height
            let heightContent = postContentItemsUIView.sizeThatFits(targetSize).height
            let footerHeight = footerViewHostingVC.sizeThatFits(in: targetSize).height
            let heightVerticalSpacing = 2 * contentVerticalSpacing

            let totalHeight = headerHeight + heightContent + footerHeight + heightVerticalSpacing + margin.top + margin.bottom
            return CGSize(width: size.width, height: totalHeight)
        }
        return .zero
    }
}
