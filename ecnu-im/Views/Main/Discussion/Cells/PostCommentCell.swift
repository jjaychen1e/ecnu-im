//
//  PostCommentCell.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/30.
//

import Combine
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

    func update(discussion: FlarumDiscussion,
                post: FlarumPost,
                replyAction: @escaping () -> Void,
                editAction: @escaping () -> Void,
                hidePostAction: @escaping (Bool) -> Void,
                deletePostAction: @escaping () -> Void) {
        view.update(discussion: discussion, post: post, replyAction: replyAction, editAction: editAction, hidePostAction: hidePostAction, deletePostAction: deletePostAction)
    }

    func update(vc: UIViewController?) {
        environmentView.update(splitVC: vc?.splitViewController, nvc: vc?.navigationController, vc: vc)
    }
}

final class PostCommentCell: UITableViewCell {
    static let identifier = "PostCommentCell"

    private var subscriptions: Set<AnyCancellable> = []

    private var discussion: FlarumDiscussion?
    private var post: FlarumPost?
    private var postContentItemsUIView: PostContentItemsUIView?
    private var headerViewHostingVC: UIHostingController<PostCommentCellHeaderViewWrapper>!
    private var footerViewHostingVC: UIHostingController<PostCommentCellFooterViewWrapper>!
    private var dimmedReasonView = UILabel()

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
                PostCommentCellFooterView(discussion: .init(id: ""), post: .init(id: ""), replyAction: {}, editAction: {}, hidePostAction: { _ in }, deletePostAction: {}),
                splitVC: nil,
                nvc: nil,
                vc: nil
            ),
            ignoreSafeArea: true
        )
        footerViewHostingVC.view.backgroundColor = .clear
        contentView.addSubview(footerViewHostingVC.view)

        contentView.addSubview(dimmedReasonView)
        dimmedReasonView.font = .systemFont(ofSize: 14, weight: .bold)
        dimmedReasonView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(discussion: FlarumDiscussion,
                   post: FlarumPost,
                   viewController: UIViewController,
                   updateLayout: (() -> Void)?,
                   replyPostAction: @escaping () -> Void,
                   editAction: @escaping () -> Void,
                   hidePostAction: @escaping (Bool) -> Void,
                   deletePostAction: @escaping () -> Void) {
        if post != self.post {
            self.post = post
            subscriptions = []
            headerViewHostingVC.view.alpha = 1.0
            footerViewHostingVC.view.alpha = 1.0
            postContentItemsUIView?.alpha = 1.0
            dimmedReasonView.text = nil
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
                var errHint: String
                if !AppGlobalState.shared.tokenPrepared {
                    errHint = "登录以查看内容预览"
                } else if AppGlobalState.shared.userInfo?.isEmailConfirmed == false {
                    errHint = "无法查看预览内容，请检查账号邮箱是否已验证。"
                } else {
                    errHint = "未知错误，无法查看预览内容"
                }
                let attributedString = NSAttributedString(string: errHint)
                let postContentItemsUIView = PostContentItemsUIView(contentItems: [ContentItemParagraphUIView(attributedText: attributedString)])
                self.postContentItemsUIView = postContentItemsUIView
                contentView.addSubview(postContentItemsUIView)
            }

            headerViewHostingVC.rootView.update(post: post)
            headerViewHostingVC.rootView.update(vc: viewController)
            footerViewHostingVC.rootView.update(discussion: discussion, post: post, replyAction: replyPostAction, editAction: editAction, hidePostAction: hidePostAction, deletePostAction: deletePostAction)
            footerViewHostingVC.rootView.update(vc: viewController)

            AppGlobalState.shared.$ignoredUserIds.combineLatest(AppGlobalState.shared.blockCompletely).sink { [weak self] ignoredUserIds, blockCompletely in
                if let self = self {
                    let ignored: Bool
                    if let authorId = self.post?.author?.id, ignoredUserIds.contains(authorId) {
                        ignored = true
                    } else {
                        ignored = false
                    }
                    let color: UIColor = ignored ? .red : Asset.DynamicColors.dynamicBlack.color.withAlphaComponent(0.7)
                    let overlayText: String = {
                        var overlayTexts: [String] = []
                        if post.isHidden {
                            overlayTexts.append("已隐藏")
                        }
                        if ignored {
                            overlayTexts.append("已屏蔽")
                        }
                        return overlayTexts.joined(separator: ", ")
                    }()
                    self.dimmedReasonView.text = overlayText
                    self.dimmedReasonView.textColor = color

                    let opacity: CGFloat = {
                        if !post.isHidden, !ignored {
                            return 1.0
                        }

                        if ignored, blockCompletely {
                            return 0.0
                        }

                        return 0.3
                    }()

                    self.postContentItemsUIView?.alpha = opacity
                    self.headerViewHostingVC.view.alpha = opacity
                    self.footerViewHostingVC.view.alpha = opacity
                }
            }
            .store(in: &subscriptions)
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
//            printDebug("Cell \(post!.attributes!.number!) \(Unmanaged.passUnretained(self).toOpaque()) - \(CGSize(width: size.width, height: totalHeight))")
            return CGSize(width: size.width, height: totalHeight)
        }
        return .zero
    }
}
