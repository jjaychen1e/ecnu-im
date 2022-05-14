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
                    PostAuthorAvatarView(name: lastPostUser.attributes.displayName, url: lastPostUser.avatarURL, size: 40)
                        .onTapGesture {
                            if lastPostUser.id != user.id {
                                if let vc = uiKitEnvironment.vc {
                                    if vc.presentingViewController != nil {
                                        vc.present(ProfileCenterViewController(userId: lastPostUser.id),
                                                   animated: true)
                                    } else {
                                        UIApplication.shared.topController()?.present(ProfileCenterViewController(userId: lastPostUser.id), animated: true)
                                    }
                                } else {
                                    #if DEBUG
                                        fatalError()
                                    #endif
                                }
                            }
                        }
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
                                        Text("\(author.lastSeenAtDateDescription)在线")
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
            }
            ProfileCenterDiscussionFooterView(discussion: discussion, post: self.$lastPost)
        }
        .navigationBarHidden(true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(.leastNonzeroMagnitude))
        .onTapGesture {
            if AppGlobalState.shared.tokenPrepared {
                if let number = lastPost?.attributes?.number {
                    if let vc = uiKitEnvironment.vc {
                        if vc.presentingViewController != nil {
                            vc.present(DiscussionViewController(discussion: discussion, nearNumber: number),
                                       animated: true)
                        } else if let splitVC = uiKitEnvironment.splitVC {
                            splitVC.push(viewController: DiscussionViewController(discussion: discussion, nearNumber: number),
                                         column: .secondary,
                                         toRoot: true)
                        } else {
                            #if DEBUG
                                fatalError()
                            #endif
                        }
                    } else {
                        #if DEBUG
                            fatalError()
                        #endif
                    }
                }
            } else {
                UIApplication.shared.topController()?.presentSignView()
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
