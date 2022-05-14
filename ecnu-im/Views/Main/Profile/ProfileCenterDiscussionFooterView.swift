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

    var replyHint: some View {
        Group {
            if repliedPosts.count > 0 {
                let threshold = 3
                let likesUserName = Set(repliedPosts.compactMap { $0.author?.attributes.displayName }).prefix(threshold).joined(separator: ", ")
                    + "\(repliedPosts.count > 3 ? "等\(repliedPosts.count)人" : "")"
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
            }
        }
    }

    var buttons: some View {
        HStack(spacing: 12) {
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
                VStack(alignment: .leading, spacing: 4) {
                    likeHint
                    replyHint
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
