//
//  PostCommentCellFooterView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/10.
//

import SwiftUI
import SwiftyJSON

struct AnimatableLiked: Equatable {
    var liked: Bool
    var animated: Bool

    init(_ liked: Bool, _ animated: Bool = false) {
        self.liked = liked
        self.animated = animated
    }

    static func animated(_ liked: Bool) -> AnimatableLiked {
        AnimatableLiked(liked, true)
    }
}

class PostCommentCellFooterViewModel: ObservableObject {
    @Published var post: FlarumPost
    @Published var animatableLiked: AnimatableLiked
    @Published var likedUsers: [FlarumUser]
    @Published var repliedPosts: [FlarumPost]
    @Published var replyAction: () -> Void
    @Published var editAction: () -> Void
    @Published var hidePostAction: (Bool) -> Void
    @Published var deletePostAction: () -> Void

    init(post: FlarumPost,
         replyAction: @escaping () -> Void,
         editAction: @escaping () -> Void,
         hidePostAction: @escaping (Bool) -> Void,
         deletePostAction: @escaping () -> Void) {
        self.post = post
        let likesUsers = post.relationships?.likes ?? []
        likedUsers = likesUsers
        animatableLiked = AnimatableLiked(AppGlobalState.shared.userId != "" && likesUsers.contains { $0.id == AppGlobalState.shared.userId })
        repliedPosts = post.relationships?.mentionedBy ?? []
        self.replyAction = replyAction
        self.editAction = editAction
        self.hidePostAction = hidePostAction
        self.deletePostAction = deletePostAction
    }

    func update(post: FlarumPost,
                replyAction: @escaping () -> Void,
                editAction: @escaping () -> Void,
                hidePostAction: @escaping (Bool) -> Void,
                deletePostAction: @escaping () -> Void) {
        self.post = post
        let likesUsers = post.relationships?.likes ?? []
        likedUsers = likesUsers
        animatableLiked = AnimatableLiked(AppGlobalState.shared.userId != "" && likesUsers.contains { $0.id == AppGlobalState.shared.userId })
        repliedPosts = post.relationships?.mentionedBy ?? []
        self.replyAction = replyAction
        self.editAction = editAction
        self.hidePostAction = hidePostAction
        self.deletePostAction = deletePostAction
    }
}

struct PostCommentCellFooterView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject private var viewModel: PostCommentCellFooterViewModel
    @State private var showMoreMenu = false

    @State private var likedActionNetworkTask: Task<Void, Never>?

    init(post: FlarumPost,
         replyAction: @escaping () -> Void,
         editAction: @escaping () -> Void,
         hidePostAction: @escaping (Bool) -> Void,
         deletePostAction: @escaping () -> Void) {
        viewModel = .init(post: post, replyAction: replyAction, editAction: editAction, hidePostAction: hidePostAction, deletePostAction: deletePostAction)
    }

    func update(post: FlarumPost,
                replyAction: @escaping () -> Void,
                editAction: @escaping () -> Void,
                hidePostAction: @escaping (Bool) -> Void,
                deletePostAction: @escaping () -> Void) {
        viewModel.update(post: post, replyAction: replyAction, editAction: editAction, hidePostAction: hidePostAction, deletePostAction: deletePostAction)
    }

    private func likeButtonAction() {
        likedActionNetworkTask?.cancel()
        likedActionNetworkTask = nil

        let currentLiked = viewModel.animatableLiked.liked

        if currentLiked {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.likedUsers.removeAll { $0.id == AppGlobalState.shared.userId }
            }
        }
        viewModel.animatableLiked = .animated(!currentLiked)

        likedActionNetworkTask = Task {
            if let response = try? await flarumProvider.request(.postLikeAction(id: Int(viewModel.post.id) ?? -1, like: !currentLiked)).flarumResponse() {
                guard !Task.isCancelled else {
                    return
                }
                if let posts = response.data.posts.first,
                   let user = posts.relationships?.likes?.first(where: { $0.id == AppGlobalState.shared.userId }) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.likedUsers.removeAll { $0.id == AppGlobalState.shared.userId }
                        viewModel.likedUsers.append(user)
                    }
                    viewModel.animatableLiked = .animated(true)
                    return
                }
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.likedUsers.removeAll { $0.id == AppGlobalState.shared.userId }
            }
            viewModel.animatableLiked = .animated(false)
        }
    }

    var replyHint: some View {
        Group {
            if viewModel.repliedPosts.count > 0 {
                let threshold = 3
                let likesUserName = Set(viewModel.repliedPosts.compactMap { $0.author?.attributes.displayName }).prefix(threshold).joined(separator: ", ")
                    + "\(viewModel.repliedPosts.count > 3 ? "等\(viewModel.repliedPosts.count)人" : "")"
                Group {
                    (Text(Image(systemName: "message.fill")) + Text(" \(likesUserName)回复了此贴"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.primary.opacity(0.8))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(4)
            }
        }
    }

    var likeHint: some View {
        Group {
            if viewModel.likedUsers.count > 0 {
                let threshold = 3
                let likesUserName = viewModel.likedUsers.prefix(threshold).map { $0.attributes.displayName }.joined(separator: ", ")
                    + "\(viewModel.likedUsers.count > 3 ? "等\(viewModel.likedUsers.count)人" : "")"
                Text(" \(likesUserName)觉得很赞")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary.opacity(0.8))
            }
        }
    }

    var buttons: some View {
        HStack(spacing: 12) {
            if viewModel.post.attributes?.canLike == true {
                Group {
                    TwitterLikeButton(action: {
                        likeButtonAction()
                    }, animatableLiked: $viewModel.animatableLiked)
                }
            }

            Button {
                viewModel.replyAction()
            } label: {
                Image(systemName: "message")
                    .font(.system(size: 20, weight: .regular, design: .rounded))
            }

            PopoverMenu {
                PopoverMenuItem(title: "App 问题反馈", systemImage: "exclamationmark.bubble", action: {})
                PopoverMenuItem(title: "举报", systemImage: "exclamationmark.circle", action: {})
                if viewModel.post.attributes?.canEdit == true {
                    PopoverMenuItem(title: "编辑", systemImage: "pencil", action: {
                        viewModel.editAction()
                    })
                }
                if viewModel.post.attributes?.canHide == true {
                    if viewModel.post.attributes?.isHidden == true {
                        PopoverMenuItem(title: "取消隐藏", systemImage: "eye", action: {
                            let alertController = UIAlertController(title: "注意", message: "你确定要取消隐藏该贴吗？", preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "确定", style: .destructive, handler: { action in
                                viewModel.hidePostAction(false)
                            }))
                            alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { action in

                            }))
                            UIApplication.shared.topController()?.present(alertController, animated: true)
                        })
                    } else {
                        PopoverMenuItem(title: "隐藏", systemImage: "eye.slash", action: {
                            let alertController = UIAlertController(title: "注意", message: "你确定要隐藏该贴吗？", preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "确定", style: .destructive, handler: { action in
                                viewModel.hidePostAction(true)
                            }))
                            alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { action in

                            }))
                            UIApplication.shared.topController()?.present(alertController, animated: true)
                        })
                    }
                }

                if viewModel.post.attributes?.canDelete == true {
                    PopoverMenuItem(title: "永久删除", systemImage: "trash", titleColor: .red, iconColor: .red, action: {
                        let alertController = UIAlertController(title: "注意", message: "你确定要永久删除该贴吗？该操作无法撤销。", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "确定", style: .destructive, handler: { action in
                            viewModel.deletePostAction()
                        }))
                        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { action in

                        }))
                        UIApplication.shared.topController()?.present(alertController, animated: true)
                    })
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .regular, design: .rounded))
            }
        }
        .foregroundColor(.primary.opacity(0.7))
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom, spacing: 12) {
                if horizontalSizeClass == .regular {
                    replyHint
                }

                Spacer(minLength: 0)

                likeHint

                buttons
            }

            if horizontalSizeClass == .compact {
                replyHint
            }
        }
        .padding(.top, 4)
        .padding(.trailing, 4)
        .padding(.leading, 4)
    }
}
