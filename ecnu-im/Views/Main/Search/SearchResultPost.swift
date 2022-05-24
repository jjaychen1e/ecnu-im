//
//  SearchResultPost.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/24.
//

import SwiftUI

struct SearchResultPost: View {
    @Binding var discussion: FlarumDiscussion

    var overlappingAvatarView: some View {
        PostAuthorAvatarView(name: discussion.starterName, url: discussion.starterAvatarURL, size: 40)
            .mask(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 1))
            .overlay(
                Group {
                    if discussion.firstPost?.id != discussion.mostRelevantPost?.id {
                        PostAuthorAvatarView(name: discussion.mostRelevantPostedUserName, url: discussion.mostRelevantPostUserAvatarURL, size: 25)
                            .mask(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                            .overlay(
                                Color.primary.opacity(0.001)
                                    .offset(x: 10, y: 10)
                                    .onTapGesture {
                                        if let targetId = discussion.mostRelevantPostUser?.id {
                                            if let account = AppGlobalState.shared.account,
                                               targetId != account.userIdString {
                                                UIApplication.shared.topController()?.present(ProfileCenterViewController(userId: targetId), animated: true)
                                            } else {
                                                let number = discussion.mostRelevantPost?.attributes?.number ?? 1
                                                UIApplication.shared.topController()?.present(DiscussionViewController(discussion: discussion, nearNumber: number), animated: true)
                                            }
                                        }
                                    }
                            )
                            .offset(x: 5, y: 0)
                    }
                },
                alignment: .bottomTrailing
            )
            .onTapGesture {
                if let targetId = discussion.starter?.id {
                    if let account = AppGlobalState.shared.account,
                       targetId != account.userIdString {
                        UIApplication.shared.topController()?.present(ProfileCenterViewController(userId: targetId), animated: true)
                    } else {
                        let number = discussion.mostRelevantPost?.attributes?.number ?? 1
                        UIApplication.shared.topController()?.present(DiscussionViewController(discussion: discussion, nearNumber: number), animated: true)
                    }
                }
            }
    }

    var replyHint: some View {
        Group {
            let repliedPosts: [FlarumPost] = discussion.mostRelevantPost?.relationships?.mentionedBy ?? []
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
            let likedUsers: [FlarumUser] = discussion.mostRelevantPost?.relationships?.likes ?? []
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

    var body: some View {
        VStack {
            HStack {
                overlappingAvatarView
                VStack(alignment: .leading, spacing: 0) {
                    Text(discussion.discussionTitle)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                    if let mostRelevantPost = discussion.mostRelevantPost {
                        HStack {
                            Text(discussion.mostRelevantPostedUserName)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                            Text(mostRelevantPost.createdDateDescription)
                                .font(.system(size: 13, weight: .light, design: .rounded))
                            Spacer(minLength: 0)
                            DiscussionTagsView(tags: .constant(discussion.tags.mappedTagViewModels), fontSize: 14)
                        }
                    }
                }
            }
            if let mostRelevantPost = discussion.mostRelevantPost {
                VStack {
                    let configuration = ContentParser.ContentExcerpt.ContentExcerptConfiguration(textLengthMax: 200, textLineMax: 4, imageCountMax: 0)
                    if let excerptText = mostRelevantPost.excerptText(configuration: configuration) {
                        Text(excerptText)
                            .animation(nil)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .truncationMode(.tail)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.0001))
        .onTapGesture {
            let number = discussion.mostRelevantPost?.attributes?.number ?? 1
            UIApplication.shared.topController()?.present(DiscussionViewController(discussion: discussion, nearNumber: number), animated: true)
        }
    }
}
