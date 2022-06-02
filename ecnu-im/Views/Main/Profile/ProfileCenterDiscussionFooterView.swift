//
//  ProfileCenterDiscussionFooterView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/14.
//

import SwiftUI

struct ProfileCenterDiscussionFooterView: View {
    @State var discussion: FlarumDiscussion
    @Binding var post: FlarumPost?
    @State var likedUsers: [FlarumUser]
    @State var repliedPosts: [FlarumPost]

    init(discussion: FlarumDiscussion, post: Binding<FlarumPost?>) {
        self.discussion = discussion
        _post = post
        likedUsers = post.wrappedValue?.relationships?.likes ?? []
        repliedPosts = post.wrappedValue?.relationships?.mentionedBy ?? []
    }

    var likeHint: some View {
        Group {
            if likedUsers.count > 0 {
                let threshold = 3
                let likesUserName = likedUsers.prefix(threshold).map { $0.attributes.displayName }.joined(separator: ", ")
                    + "\(likedUsers.count > 3 ? "等\(likedUsers.count)人" : "")"
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
                    UIApplication.shared.presentOnTop(LikeListViewController(users: likedUsers))
                }
            }
        }
        .onChange(of: post, perform: { newValue in
            if let post = newValue {
                Task {
                    if let id = Int(post.id),
                       let likedUsers = try? await flarumProvider.request(.postsById(id: id, includes: [.likes])).flarumResponse().data.posts.first?.relationships?.likes {
                        self.likedUsers = likedUsers
                    }
                }
            }
        })
    }

    var buttons: some View {
        PopoverMenu {
            PopoverMenuLabelItem(title: "App 问题反馈", systemImage: "exclamationmark.bubble", action: {})
                .disabled(true)
            PopoverMenuLabelItem(title: "分享", systemImage: "square.and.arrow.up", action: {})
                .disabled(true)

            if let number = post?.attributes?.number,
               let url = URL(string: URLService.link(href: "https://ecnu.im/d/\(discussion.id)/\(number)").url) {
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
                }
                Spacer(minLength: 0)
                buttons
            }
        }
        .padding(.bottom, 4)
        .onChange(of: post) { newValue in
            likedUsers = newValue?.relationships?.likes ?? []
            repliedPosts = newValue?.relationships?.mentionedBy ?? []
        }
    }
}
