//
//  PostCommentCellFooterView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/10.
//

import SwiftUI
import SwiftyJSON

class PostCommentCellFooterViewModel: ObservableObject {
    @Published var post: FlarumPost
    @Published var liked: Bool
    @Published var likedUsers: [FlarumUser]
    @Published var repliedPosts: [FlarumPost]
    @Published var replyAction: () -> Void

    init(post: FlarumPost, replyAction: @escaping () -> Void) {
        self.post = post
        let likesUsers = post.relationships?.likes ?? []
        likedUsers = likesUsers
        liked = AppGlobalState.shared.userId != "" && likesUsers.contains { $0.id == AppGlobalState.shared.userId }
        repliedPosts = post.relationships?.mentionedBy ?? []
        self.replyAction = replyAction
    }

    func update(post: FlarumPost, replyAction: @escaping () -> Void) {
        self.post = post
        let likesUsers = post.relationships?.likes ?? []
        likedUsers = likesUsers
        liked = AppGlobalState.shared.userId != "" && likesUsers.contains { $0.id == AppGlobalState.shared.userId }
        repliedPosts = post.relationships?.mentionedBy ?? []
        self.replyAction = replyAction
    }
}

struct PostCommentCellFooterView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject private var viewModel: PostCommentCellFooterViewModel

    init(post: FlarumPost, replyAction: @escaping () -> Void) {
        viewModel = .init(post: post, replyAction: replyAction)
    }

    func update(post: FlarumPost, replyAction: @escaping () -> Void) {
        viewModel.update(post: post, replyAction: replyAction)
    }

    private func likeButtonAction() {
        let currentLiked = viewModel.liked
        Task {
            if let response = try? await flarumProvider.request(.postLikeAction(id: Int(viewModel.post.id) ?? -1, like: !currentLiked)) {
                let json = JSON(response.data)
                let flarumResponse = FlarumResponse(json: json)
                if let posts = flarumResponse.data.posts.first,
                   let user = posts.relationships?.likes?.first(where: { $0.id == AppGlobalState.shared.userId }) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.likedUsers.removeAll { $0.id == AppGlobalState.shared.userId }
                        viewModel.likedUsers.append(user)
                        viewModel.liked = true
                    }
                    return
                }
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.liked = false
                viewModel.likedUsers.removeAll { $0.id == AppGlobalState.shared.userId }
            }
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.liked.toggle()
            if !viewModel.liked {
                viewModel.likedUsers.removeAll { $0.id == AppGlobalState.shared.userId }
            }
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
                    if viewModel.liked {
                        Button {
                            likeButtonAction()
                        } label: {
                            Image(systemName: "hand.thumbsup.fill")
                                .font(.system(size: 20, weight: .regular, design: .rounded))
                        }
                    } else {
                        Button {
                            likeButtonAction()
                        } label: {
                            Image(systemName: "hand.thumbsup")
                                .font(.system(size: 20, weight: .regular, design: .rounded))
                        }
                    }
                }
            }

            Button {
                viewModel.replyAction()
            } label: {
                Image(systemName: "message")
                    .font(.system(size: 20, weight: .regular, design: .rounded))
            }

            Button {} label: {
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
