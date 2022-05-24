//
//  DiscussionListCell.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/27.
//

import Kingfisher
import SwiftSoup
import SwiftUI
import UIColorHexSwift

struct DiscussionListCellPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Circle()
                    .fill(Color(rgba: "#D6D6D6"))
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("那只敏捷的棕毛狐狸跳过那只懒狗，消失得无影无踪。")
                        .font(.system(size: 17, weight: .bold))
                    HStack(alignment: .center, spacing: 2) {
                        Text("jjaychen")
                            .font(.system(size: 15, weight: .medium))
                        Text("1 分钟前")
                            .font(.system(size: 12, weight: .light))
                            .frame(alignment: .leading)
                    }
                }
                Spacer(minLength: 0)
            }
            Text(String(repeating: " ", count: Int.random(in: 40 ..< 80)))
            Text(String(repeating: " ", count: Int.random(in: 40 ..< 80)))
            Text(String(repeating: " ", count: Int.random(in: 40 ..< 80)))
        }
        .padding(.horizontal, 16)
        .redacted(reason: .placeholder)
    }
}

class DiscussionListCellViewModel: ObservableObject {
    @Published var discussion: FlarumDiscussion
    @Published var relatedUsers: [FlarumUser] = []
    @Published var completedLastPost: FlarumPost?
    @Published var completedFirstPost: FlarumPost?

    init(discussion: FlarumDiscussion) {
        self.discussion = discussion
        completedLastPost = nil
        completedFirstPost = nil
    }
}

struct DiscussionListCell: View {
    @EnvironmentObject var uiKitEnvironment: UIKitEnvironment
    @ObservedObject private var viewModel: DiscussionListCellViewModel

    init(viewModel: DiscussionListCellViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 8) {
            Button {
                let near = viewModel.discussion.attributes?.lastPostNumber ?? 1
                uiKitEnvironment.splitVC?.push(viewController: DiscussionViewController(discussion: viewModel.discussion, nearNumber: near),
                                               column: .secondary,
                                               toRoot: true)
            } label: {
                LastPostCell(viewModel: viewModel)
                    .background(Color.white.opacity(0.001))
            }
            .buttonStyle(.plain)

            if viewModel.discussion.firstPost != nil
                && viewModel.discussion.lastPost != nil
                && viewModel.discussion.firstPost != viewModel.discussion.lastPost {
                Button {
                    uiKitEnvironment.splitVC?.push(viewController: DiscussionViewController(discussion: viewModel.discussion, nearNumber: 0),
                                                   column: .secondary,
                                                   toRoot: true)
                } label: {
                    FirstPostCell(viewModel: viewModel)
                        .background(Color.white.opacity(0.001))
                }
                .buttonStyle(.plain)
            }

            if viewModel.discussion.firstPost == nil {
                Text("原帖一楼已删除")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.primary.opacity(0.3))
            }

            HStack(spacing: 4) {
                likeHint
                Spacer(minLength: 0)
                HStack(spacing: -3) {
                    ForEach(0 ..< viewModel.relatedUsers.count, id: \.self) { index in
                        let user = viewModel.relatedUsers[index]
                        PostAuthorAvatarView(name: user.attributes.displayName, url: user.avatarURL, size: 18)
                            .mask(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 0.5))
                    }
                }
                HStack(spacing: 1) {
                    HStack(spacing: 1) {
                        Image(systemName: "eye")
                            .font(.system(size: 10))
                            .frame(width: 16, height: 16)
                        Text("\(viewModel.discussion.viewCount)")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    HStack(spacing: 1) {
                        Image(systemName: "message")
                            .font(.system(size: 10))
                            .frame(width: 16, height: 16)
                        Text("\(viewModel.discussion.commentCount)")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    var likeHint: some View {
        Group {
            if let likesUsers = viewModel.completedLastPost?.relationships?.likes,
               likesUsers.count > 0 {
                let threshold = 3
                let likesUserName = likesUsers.prefix(threshold).map { $0.attributes.displayName }.joined(separator: ", ")
                    + "\(likesUsers.count > 3 ? "等\(likesUsers.count)人" : "")"
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
}

private struct FirstPostCell: View {
    @EnvironmentObject var uiKitEnvironment: UIKitEnvironment

    @ObservedObject private var viewModel: DiscussionListCellViewModel
    @State private var dateDescription: String

    init(viewModel: DiscussionListCellViewModel) {
        self.viewModel = viewModel
        dateDescription = viewModel.discussion.firstPostDateDescription
    }

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                PostAuthorAvatarView(name: viewModel.discussion.starterName,
                                     url: viewModel.discussion.starterAvatarURL,
                                     size: 30)
                    .onTapGesture {
                        if let targetId = viewModel.discussion.starter?.id {
                            if let account = AppGlobalState.shared.account,
                               targetId != account.userIdString {
                                UIApplication.shared.topController()?.present(ProfileCenterViewController(userId: targetId), animated: true)
                            } else {
                                let number = viewModel.discussion.attributes?.lastPostNumber ?? 1
                                uiKitEnvironment.splitVC?.push(viewController: DiscussionViewController(discussion: viewModel.discussion, nearNumber: number),
                                                               column: .secondary,
                                                               toRoot: true)
                            }
                        }
                    }

                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.discussion.discussionTitle)
                        .font(.system(size: 15, weight: .bold))
                    HStack {
                        Text(viewModel.discussion.starterName)
                            .font(.system(size: 12, weight: .medium))
                        Text(dateDescription)
                            .font(.system(size: 10, weight: .light))
                    }
                }
                Spacer(minLength: 0)
                Group {
                    Text(Image(systemName: "message.fill")) + Text(" 原帖")
                }
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .regular))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(rgba: "#1976d2"))
                )
            }
            if let completedLastPost = viewModel.completedFirstPost {
                let configuration = ContentParser.ContentExcerpt.ContentExcerptConfiguration(textLengthMax: 500, textLineMax: 5, imageCountMax: 0)
                if let excerptText = completedLastPost.excerptText(configuration: configuration) {
                    Text(excerptText)
                        .animation(nil)
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                        .truncationMode(.tail)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            if let repliedPosts = viewModel.completedFirstPost?.relationships?.mentionedBy, repliedPosts.count > 0 {
                if let likesUsers = viewModel.completedFirstPost?.relationships?.likes, likesUsers.count > 0 {
                    HStack {
                        likeHint
                        Spacer(minLength: 0)
                        replyHint
                    }
                }
            }
        }
        .padding(.all, 8)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            dateDescription = viewModel.discussion.firstPostDateDescription
        }
    }

    var replyHint: some View {
        Group {
            if let repliedPosts = viewModel.completedFirstPost?.relationships?.mentionedBy,
               repliedPosts.count > 0 {
                let threshold = 3
                let repliedPostsName = Set(repliedPosts.compactMap { $0.author?.attributes.displayName }).prefix(threshold).joined(separator: ", ")
                    + "\(repliedPosts.count > 3 ? "等\(repliedPosts.count)人" : "")"
                Group {
                    (Text(Image(systemName: "message.fill")) + Text(" \(repliedPostsName)回复了此贴"))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
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
            if let likesUsers = viewModel.completedFirstPost?.relationships?.likes,
               likesUsers.count > 0 {
                let threshold = 3
                let likesUserName = likesUsers.prefix(threshold).map { $0.attributes.displayName }.joined(separator: ", ")
                    + "\(likesUsers.count > 3 ? "等\(likesUsers.count)人" : "")"
                Group {
                    (Text(Image(systemName: "heart.fill")) + Text(" \(likesUserName)觉得很赞"))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.primary.opacity(0.8))
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.primary.opacity(0.8))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(4)
            }
        }
    }
}

private struct LastPostCell: View {
    @EnvironmentObject var uiKitEnvironment: UIKitEnvironment
    @ObservedObject private var viewModel: DiscussionListCellViewModel
    @State private var dateDescription: String

    init(viewModel: DiscussionListCellViewModel) {
        self.viewModel = viewModel
        dateDescription = viewModel.discussion.lastPostDateDescription
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                PostAuthorAvatarView(name: viewModel.discussion.lastPostedUserName,
                                     url: viewModel.discussion.lastPostedUserAvatarURL,
                                     size: 40)
                    .onTapGesture {
                        if let targetId = viewModel.discussion.starter?.id {
                            if let account = AppGlobalState.shared.account,
                               targetId != account.userIdString {
                                UIApplication.shared.topController()?.present(ProfileCenterViewController(userId: targetId), animated: true)
                            } else {
                                let number = viewModel.discussion.attributes?.lastPostNumber ?? 1
                                uiKitEnvironment.splitVC?.push(viewController: DiscussionViewController(discussion: viewModel.discussion, nearNumber: number),
                                                               column: .secondary,
                                                               toRoot: true)
                            }
                        }
                    }
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.discussion.discussionTitle)
                        .font(.system(size: 17, weight: .bold))
                    HStack(alignment: .center, spacing: 2) {
                        Text(viewModel.discussion.lastPostedUserName)
                            .font(.system(size: 15, weight: .medium))
                        HStack(spacing: 2) {
                            Text(dateDescription)
                                .font(.system(size: 12, weight: .light))
                                .fixedSize()
                            Spacer(minLength: 0)
                            DiscussionTagsView(tags: .constant(viewModel.discussion.tagViewModels), fontSize: 14, horizontalPadding: 6, verticalPadding: 4, cornerRadius: 5)
                                .fixedSize()
                        }
                    }
                }
            }
            if let completedLastPost = viewModel.completedLastPost {
                let configuration = ContentParser.ContentExcerpt.ContentExcerptConfiguration(textLengthMax: 500, textLineMax: 5, imageCountMax: 0)
                if let excerptText = completedLastPost.excerptText(configuration: configuration) {
                    Text(excerptText)
                        .animation(nil)
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                        .truncationMode(.tail)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
        .onAppear {
            dateDescription = viewModel.discussion.lastPostDateDescription
        }
    }
}
