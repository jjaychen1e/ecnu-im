//
//  ReplyListView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/24.
//

import SwiftUI

private struct ReplyPostView: View {
    @State var discussion: FlarumDiscussion
    @State var originalPost: FlarumPost
    @State var post: FlarumPost
    @State private var fetchedPost: FlarumPost? = nil
    @State private var fetchedDiscussion: FlarumDiscussion? = nil

    var overlappingAvatarView: some View {
        PostAuthorAvatarView(name: originalPost.authorName, url: originalPost.authorAvatarURL, size: 40)
            .mask(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 1))
            .overlay(
                Group {
                    if let fetchedDiscussion = fetchedDiscussion, fetchedDiscussion.firstPost?.id != post.id {
                        PostAuthorAvatarView(name: post.authorName, url: post.authorAvatarURL, size: 25)
                            .mask(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                            .overlay(
                                Color.primary.opacity(0.001)
                                    .offset(x: 10, y: 10)
                                    .onTapGesture {
                                        if let targetId = post.author?.id,
                                           let account = AppGlobalState.shared.account,
                                           targetId != account.userIdString {
                                            UIApplication.shared.presentOnTop(ProfileCenterViewController(userId: targetId), animated: true)
                                        }
                                    }
                            )
                            .offset(x: 5, y: 0)
                    }
                },
                alignment: .bottomTrailing
            )
            .onTapGesture {
                if let targetId = originalPost.author?.id,
                   let account = AppGlobalState.shared.account,
                   targetId != account.userIdString {
                    UIApplication.shared.presentOnTop(ProfileCenterViewController(userId: targetId), animated: true)
                }
            }
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                overlappingAvatarView
                VStack(alignment: .leading, spacing: 0) {
                    Text(discussion.discussionTitle)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                    HStack {
                        Text("@" + post.authorName)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Text(post.createdDateDescription)
                            .font(.system(size: 14, weight: .light, design: .rounded))
                        Spacer(minLength: 0)
                    }
                }
            }

            if let fetchedPost = fetchedPost {
                VStack {
                    let configuration = ContentParser.ContentExcerpt.ContentExcerptConfiguration(textLengthMax: 200, textLineMax: 4, imageCountMax: 0)
                    if let excerptText = fetchedPost.excerptText(configuration: configuration) {
                        Text(excerptText)
                            .animation(nil)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .truncationMode(.tail)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
            }
        }
        .onLoad {
            Task {
                if let id = Int(post.id),
                   let post = try? await flarumProvider.request(.postsById(id: id, includes: [])).flarumResponse().data.posts.first {
                    self.fetchedPost = post
                }
            }

            Task {
                if let id = Int(discussion.id),
                   let discussion = try? await flarumProvider.request(.discussionInfo(discussionID: id)).flarumResponse().data.discussions.first {
                    withAnimation {
                        self.fetchedDiscussion = discussion
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.0001))
        .onTapGesture {
            let number = fetchedPost?.attributes?.number ?? 1
            UIApplication.shared.presentOnTop(DiscussionViewController(discussion: discussion, nearNumber: number))
        }
    }
}

struct ReplyListView: View {
    @Environment(\.dismiss) var dismiss
    @State var discussion: FlarumDiscussion
    @State var originalPost: FlarumPost
    @State var posts: [FlarumPost]

    var body: some View {
        NavigationView {
            List {
                ForEach(posts, id: \.self) { post in
                    ReplyPostView(discussion: discussion, originalPost: originalPost, post: post)
                }
            }
            .navigationTitle("这篇帖子的回复")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("完成")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
