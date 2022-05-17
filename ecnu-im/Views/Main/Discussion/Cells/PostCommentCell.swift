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

private struct PostCommentCellHeaderViewWrapper: View {
    private var view: PostCommentCellHeaderView
    private let environmentView: EnvironmentWrapperView<PostCommentCellHeaderView>

    init(_ view: PostCommentCellHeaderView, splitVC: UISplitViewController?, nvc: UINavigationController?, vc: UIViewController?) {
        self.view = view
        environmentView = EnvironmentWrapperView(view, splitVC: splitVC, nvc: nvc, vc: vc)
    }

    var body: some View {
        environmentView
    }

    func update(post: FlarumPost) {
        view.update(post: post)
    }

    func update(vc: UIViewController?) {
        environmentView.update(splitVC: vc?.splitViewController, nvc: vc?.navigationController, vc: vc)
    }
}

private struct PostCommentCellFooterViewWrapper: View {
    private var view: PostCommentCellFooterView

    private let environmentView: EnvironmentWrapperView<PostCommentCellFooterView>

    init(_ view: PostCommentCellFooterView, splitVC: UISplitViewController?, nvc: UINavigationController?, vc: UIViewController?) {
        self.view = view
        environmentView = EnvironmentWrapperView(view, splitVC: splitVC, nvc: nvc, vc: vc)
    }

    var body: some View {
        environmentView
    }

    func update(post: FlarumPost,
                replyAction: @escaping () -> Void,
                hidePostAction: @escaping (Bool) -> Void,
                deletePostAction: @escaping () -> Void) {
        view.update(post: post, replyAction: replyAction, hidePostAction: hidePostAction, deletePostAction: deletePostAction)
    }

    func update(vc: UIViewController?) {
        environmentView.update(splitVC: vc?.splitViewController, nvc: vc?.navigationController, vc: vc)
    }
}

final class PostCommentCell: UITableViewCell {
    static let identifier = "PostCommentCell"

    private var post: FlarumPost?
    private var postContentItemsUIView: PostContentItemsUIView?
    private var headerViewHostingVC: UIHostingController<PostCommentCellHeaderViewWrapper>!
    private var footerViewHostingVC: UIHostingController<PostCommentCellFooterViewWrapper>!

    private let avatarViewSize: CGFloat = 40.0
    private let avatarContentMargin: CGFloat = 8.0
    private let contentVerticalSpacing: CGFloat = 4.0
    private var margin: UIEdgeInsets {
        DiscussionViewController.margin
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = DiscussionViewController.backgroundColor

        headerViewHostingVC = UIHostingController(
            rootView:
            PostCommentCellHeaderViewWrapper(
                PostCommentCellHeaderView(post: .init(id: "")),
                splitVC: nil,
                nvc: nil,
                vc: nil
            ),
            ignoreSafeArea: true
        )
        headerViewHostingVC.view.backgroundColor = .clear
        contentView.addSubview(headerViewHostingVC.view)

        footerViewHostingVC = UIHostingController(
            rootView:
            PostCommentCellFooterViewWrapper(
                PostCommentCellFooterView(post: .init(id: ""), replyAction: {}, hidePostAction: { _ in }, deletePostAction: {}),
                splitVC: nil,
                nvc: nil,
                vc: nil
            ),
            ignoreSafeArea: true
        )
        footerViewHostingVC.view.backgroundColor = .clear
        contentView.addSubview(footerViewHostingVC.view)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(post: FlarumPost,
                   viewController: UIViewController,
                   updateLayout: (() -> Void)?,
                   replyPostAction: @escaping () -> Void,
                   hidePostAction: @escaping (Bool) -> Void,
                   deletePostAction: @escaping () -> Void) {
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
            headerViewHostingVC.rootView.update(vc: viewController)
            footerViewHostingVC.rootView.update(post: post, replyAction: replyPostAction, hidePostAction: hidePostAction, deletePostAction: deletePostAction)
            footerViewHostingVC.rootView.update(vc: viewController)

            if post.attributes?.isHidden == true {
                contentView.alpha = 0.3
            } else {
                contentView.alpha = 1.0
            }
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

            let headerHeight = headerViewHostingVC.rootView.adaptiveSizeThatFits(in: targetSize, for: traitCollection.horizontalSizeClass).height
            let heightContent = postContentItemsUIView.sizeThatFits(targetSize).height
            let footerHeight = footerViewHostingVC.rootView.adaptiveSizeThatFits(in: targetSize, for: traitCollection.horizontalSizeClass).height
            let heightVerticalSpacing = 2 * contentVerticalSpacing

            let totalHeight = headerHeight + heightContent + footerHeight + heightVerticalSpacing + margin.top + margin.bottom
//            print("Cell \(post!.attributes!.number!) \(Unmanaged.passUnretained(self).toOpaque()) - \(CGSize(width: size.width, height: totalHeight))")
            return CGSize(width: size.width, height: totalHeight)
        }
        return .zero
    }
}
