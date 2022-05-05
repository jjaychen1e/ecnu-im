//
//  PostCommentCell.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/30.
//

import SnapKit
import SwiftUI
import UIKit

final class PostCommentCell: UITableViewCell {
    static let identifier = "PostCommentCell"
    private var post: FlarumPost?
    private var postContentItemsUIView: PostContentItemsUIView?

    func configure(post: FlarumPost, updateLayout: (() -> Void)?) {
        if post != self.post {
            self.post = post
            postContentItemsUIView?.removeFromSuperview()

            if let content = post.attributes?.content, case let .comment(comment) = content {
                let parseConfiguration = ParseConfiguration(imageOnTapAction: { ImageBrowser.shared.present(imageURLs: $1, selectedImageIndex: $0) },
                                                            imageGridDisplayMode: .narrow)
                let contentParser = ContentParser(content: comment, configuration: parseConfiguration, updateLayout: updateLayout)
                let newContentItems = contentParser.parse()
                if newContentItems.count > 0 {
                    let postContentItemsUIView = PostContentItemsUIView(contentItems: newContentItems)
                    self.postContentItemsUIView = postContentItemsUIView
                    contentView.addSubview(postContentItemsUIView)
                }
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let margin = DiscussionViewController.margin
        let availableWidth = bounds.width - margin.left - margin.right
        let contentSize = postContentItemsUIView?.sizeThatFits(CGSize(width: availableWidth, height: .greatestFiniteMagnitude)) ?? .zero
        postContentItemsUIView?.frame = .init(origin: .init(x: margin.left, y: margin.top), size: contentSize)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let margin = DiscussionViewController.margin
        let availableWidth = size.width - margin.left - margin.right
        let contentSize = postContentItemsUIView?.sizeThatFits(CGSize(width: availableWidth, height: .greatestFiniteMagnitude)) ?? .zero
        return CGSize(width: size.width, height: contentSize.height + margin.top + margin.bottom)
    }
}
