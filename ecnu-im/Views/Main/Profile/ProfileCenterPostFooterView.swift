//
//  ProfileCenterPostFooterView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/14.
//

import SwiftUI

class ProfileCenterPostFooterViewModel: ObservableObject {
    @Published var discussion: FlarumDiscussion
    @Published var post: FlarumPost
    @Published var likedUsers: [FlarumUser]
    @Published var repliedPosts: [FlarumPost]

    init(discussion: FlarumDiscussion, post: FlarumPost) {
        self.discussion = discussion
        self.post = post
        let likesUsers = post.relationships?.likes ?? []
        likedUsers = likesUsers
        repliedPosts = post.relationships?.mentionedBy ?? []
    }
}

struct ProfileCenterPostFooterView: View {
    @ObservedObject private var viewModel: ProfileCenterPostFooterViewModel

    init(discussion: FlarumDiscussion, post: FlarumPost) {
        viewModel = .init(discussion: discussion, post: post)
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
                .onTapGesture {
                    UIApplication.shared.presentOnTop(ReplyListViewController(discussion: viewModel.discussion, originalPost: viewModel.post, posts: viewModel.repliedPosts))
                }
            }
        }
    }

    var likeHint: some View {
        Group {
            if viewModel.likedUsers.count > 0 {
                let threshold = 3
                let likesUserName = viewModel.likedUsers.prefix(threshold).map { $0.attributes.displayName }.joined(separator: ", ")
                    + "\(viewModel.likedUsers.count > 3 ? "等\(viewModel.likedUsers.count)人" : "")"
                Group {
                    (Text(Image(systemName: "heart.fill")) + Text(" \(likesUserName)觉得很赞"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.primary.opacity(0.8))
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.primary.opacity(0.8))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(4)
                .onTapGesture {
                    UIApplication.shared.presentOnTop(LikeListViewController(users: viewModel.likedUsers))
                }
            }
        }
    }

    var buttons: some View {
        PopoverMenu {
            PopoverMenuLabelItem(title: "App 问题反馈", systemImage: "exclamationmark.bubble", action: {})
                .disabled(true)
            PopoverMenuLabelItem(title: "分享", systemImage: "square.and.arrow.up", action: {})
                .disabled(true)

            if let number = viewModel.post.attributes?.number,
               let url = URL(string: URLService.link(href: "https://ecnu.im/d/\(viewModel.discussion.id)/\(number)").url) {
                PopoverMenuLabelItem(title: "打开网页版", systemImage: "safari", action: {
                    UIApplication.shared.open(url)
                })
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 20, weight: .regular, design: .rounded))
                .foregroundColor(.primary.opacity(0.7))
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    likeHint
                    replyHint
                }
                Spacer(minLength: 0)
                buttons
            }
        }
        .padding(.bottom, 4)
    }
}
