//
//  ProfileCenterDiscussionView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/14.
//

import SwiftUI

struct ProfileCenterDiscussionView: View {
    @EnvironmentObject var uiKitEnvironment: UIKitEnvironment
    @State var user: FlarumUser
    @State var discussion: FlarumDiscussion
    @State var lastPost: FlarumPost? = nil

    var body: some View {
        let discussionTitle = discussion.discussionTitle
        VStack(alignment: .leading, spacing: 6) {
            Text("\(discussionTitle)")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.init(rgba: "#667A99"))

            if let lastPost = lastPost,
               let lastPostUser = lastPost.author {
                let lastPostExcerptText = lastPost.excerptText(configuration: .init(textLengthMax: 200, textLineMax: 5, imageCountMax: 0)) ?? "无预览内容"
                HStack(alignment: .top) {
                    PostAuthorAvatarView(name: user.attributes.displayName, url: user.avatarURL, size: 40)
                        .mask(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                        .overlay(
                            Group {
                                if discussion.firstPost?.id != discussion.lastPost?.id {
                                    PostAuthorAvatarView(name: discussion.lastPostedUserName, url: discussion.lastPostedUserAvatarURL, size: 25)
                                        .mask(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                        .overlay(
                                            Color.primary.opacity(0.001)
                                                .offset(x: 10, y: 10)
                                                .onTapGesture {
                                                    if let targetId = discussion.lastPostedUser?.id {
                                                        if let account = AppGlobalState.shared.account,
                                                           targetId != account.userIdString {
                                                            UIApplication.shared.presentOnTop(ProfileCenterViewController(userId: targetId), animated: true)
                                                        } else {
                                                            let number = lastPost.attributes?.number ?? 1
                                                            uiKitEnvironment.splitVC?.push(viewController: DiscussionViewController(discussion: discussion, nearNumber: number),
                                                                                           column: .secondary,
                                                                                           toRoot: true)
                                                        }
                                                    }
                                                }
                                        )
                                        .offset(x: 5, y: 0)
                                }
                            },
                            alignment: .bottomTrailing
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(lastPostUser.attributes.displayName)
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                            Text(lastPost.createdDateDescription)
                                .font(.system(size: 14, weight: .light, design: .rounded))
                                .foregroundColor(.primary.opacity(0.7))
                        }

                        HStack {
                            if let author = lastPost.author {
                                if author.isOnline {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(rgba: "#7FBA00"))
                                            .frame(width: 8, height: 8)
                                        Text("在线")
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundColor(.primary.opacity(0.7))
                                    }
                                } else {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(.gray)
                                            .frame(width: 8, height: 8)
                                        Text(author.lastSeenAtDateDescription)
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundColor(.primary.opacity(0.7))
                                    }
                                }
                            }

                            if let editedDateDescription = lastPost.editedDateDescription {
                                Text("重新编辑于 \(editedDateDescription)")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.primary.opacity(0.7))
                            }
                        }
                    }
                }

                Text(lastPostExcerptText)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.primary.opacity(0.7))
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            } else {
                Text("无最新回复")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.primary.opacity(0.7))
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
            ProfileCenterDiscussionFooterView(discussion: discussion, post: self.$lastPost)
        }
        .navigationBarHidden(true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.0001))
        .onTapGesture {
            if let vc = uiKitEnvironment.vc {
                let targetNumber = lastPost?.attributes?.number ?? 1
                if vc.presentingViewController != nil {
                    vc.present(DiscussionViewController(discussion: discussion, nearNumber: targetNumber),
                               animated: true)
                } else if let splitVC = uiKitEnvironment.splitVC {
                    splitVC.push(viewController: DiscussionViewController(discussion: discussion, nearNumber: targetNumber),
                                 column: .secondary,
                                 toRoot: true)
                } else {
                    fatalErrorDebug()
                }
            } else {
                fatalErrorDebug()
            }
        }
        .onLoad {
            Task {
                if let idStr = discussion.lastPost?.id,
                   let id = Int(idStr) {
                    if let response = try? await flarumProvider.request(.postsById(id: id)).flarumResponse() {
                        self.lastPost = response.data.posts.first
                    }
                }
            }
        }
    }
}
