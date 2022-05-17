//
//  NotificationView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/17.
//

import SwiftUI

struct NotificationView: View {
    @State var notification: FlarumNotification
    @State var badgeNotificationTitle: String?
    @State var userBadge: FlarumUserBadge?
    @State var replyExcerptText: String?

    @EnvironmentObject var uiKitEnvironment: UIKitEnvironment
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let type = notification.attributes.contentType
        let relatedDiscussion = notification.relatedDiscussion
        let originalPost = notification.originalPost
        let user = notification.relationships?.fromUser

        VStack(alignment: .leading, spacing: 6) {
            Group {
                switch type {
                case .postLiked, .postMentioned, .postReacted, .privateDiscussionReplied, .privateDiscussionCreated:
                    Text(relatedDiscussion?.discussionTitle ?? "Unkown")
                case .badgeReceived:
                    Text(badgeNotificationTitle ?? "Unkown")
                }
            }
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundColor(.init(rgba: "#566A89"))

            originalPostExcerptView(post: originalPost)

            HStack {
                iconView(type: type)

                if let user = user {
                    PostAuthorAvatarView(name: user.attributes.displayName, url: user.avatarURL, size: 30)
                        .onTapGesture {
                            if let vc = uiKitEnvironment.vc {
                                if vc.presentingViewController != nil {
                                    vc.present(ProfileCenterViewController(userId: user.id),
                                               animated: true)
                                } else {
                                    UIApplication.shared.topController()?.present(ProfileCenterViewController(userId: user.id), animated: true)
                                }
                            }
                        }
                    (Text(user.attributes.displayName) + Text(" \(type.actionDescription)了你"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                }

                if let category = userBadge?.relationships?.badge.relationships?.category {
                    NotificationBadgeView(badgeCategory: category, userBadges: [userBadge!])
                }

                if type != .badgeReceived {
                    Text(notification.createdDateDescription)
                        .font(.system(size: 13, weight: .light, design: .rounded))
                }
            }

            contentExcerptView()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.all, 8)
        .background(notification.attributes.isRead ? Color.clear.opacity(0.0001) : colorScheme == .light ? Color(rgba: "#e4ebf6") : Color(rgba: "#e4ebf6").opacity(0.2))
        .onLoad {
            Task {
                if let repliedPost = await notification.repliedPost() {
                    replyExcerptText = repliedPost.excerptText(configuration: .init(textLengthMax: 150,
                                                                                    textLineMax: 3,
                                                                                    imageCountMax: 0))
                }

                if type == .badgeReceived {
                    if let subject = notification.relationships?.subject, case let .userBadge(userBadgeId) = subject {
                        if let userBadge = FlarumBadgeStorage.shared.userBadge(for: userBadgeId),
                           let badge = userBadge.relationships?.badge {
                            self.userBadge = userBadge
                            badgeNotificationTitle = "你获得了一个新徽章: \(badge.description)！"
                        } else {
                            // We need to fetch from user's api
                            Task {
                                if let id = AppGlobalState.shared.userIdInt {
                                    if let response = try? await flarumProvider.request(.user(id: id)).flarumResponse() {
                                        let userBadges = response.included.userBadges
                                        self.userBadge = userBadge
                                        FlarumBadgeStorage.shared.store(userBadges: userBadges)
                                        if let userBadge = FlarumBadgeStorage.shared.userBadge(for: userBadgeId),
                                           let badge = userBadge.relationships?.badge {
                                            badgeNotificationTitle = "你获得了一个新徽章: \(badge.description)！"
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        fatalErrorDebug()
                    }
                }
            }
        }
        .onTapGesture {
            switch notification.attributes.content {
            case .postLiked, .postReacted:
                if AppGlobalState.shared.tokenPrepared {
                    if let post = originalPost,
                       let discussion = post.relationships?.discussion,
                       let number = post.attributes?.number {
                        uiKitEnvironment.splitVC?.push(viewController: DiscussionViewController(discussion: discussion, nearNumber: number),
                                                       column: .secondary,
                                                       toRoot: true)
                    }
                } else {
                    UIApplication.shared.topController()?.presentSignView()
                }
            case let .postMentioned(replyNumber):
                if AppGlobalState.shared.tokenPrepared {
                    if let post = originalPost,
                       let discussion = post.relationships?.discussion {
                        uiKitEnvironment.splitVC?.push(viewController: DiscussionViewController(discussion: discussion, nearNumber: replyNumber),
                                                       column: .secondary,
                                                       toRoot: true)
                    }
                } else {
                    UIApplication.shared.topController()?.presentSignView()
                }
            case .badgeReceived:
                uiKitEnvironment.vc?.tabController?.select(tab: .profile, info: [ProfileCategory.key: ProfileCategory.badge])
            case let .privateDiscussionReplied(postNumber):
                if AppGlobalState.shared.tokenPrepared {
                    if let post = originalPost,
                       let discussion = post.relationships?.discussion {
                        uiKitEnvironment.splitVC?.push(viewController: DiscussionViewController(discussion: discussion, nearNumber: postNumber),
                                                       column: .secondary,
                                                       toRoot: true)
                    }
                } else {
                    UIApplication.shared.topController()?.presentSignView()
                }
            case .privateDiscussionCreated:
                if AppGlobalState.shared.tokenPrepared {
                    if let post = originalPost,
                       let discussion = post.relationships?.discussion {
                        uiKitEnvironment.splitVC?.push(viewController: DiscussionViewController(discussion: discussion, nearOffset: 0),
                                                       column: .secondary,
                                                       toRoot: true)
                    }
                } else {
                    UIApplication.shared.topController()?.presentSignView()
                }
            }
        }
    }

    @ViewBuilder
    func iconView(type: FlarumNotificationAttributes.FlarumNotificationContentType) -> some View {
        switch type {
        case .postLiked:
            Image(systemName: "heart.fill")
                .foregroundColor(.pink)
        case .postMentioned:
            Image(systemName: "message.fill")
                .foregroundColor(.blue)
        case .postReacted:
            Image(systemName: "hands.sparkles.fill")
                .foregroundColor(.purple)
        case .badgeReceived:
            EmptyView()
        case .privateDiscussionReplied:
            Image(systemName: "lock.fill")
                .foregroundColor(.orange)
        case .privateDiscussionCreated:
            Image(systemName: "lock.fill")
                .foregroundColor(.orange)
        }
    }

    @ViewBuilder
    func originalPostExcerptView(post: FlarumPost?) -> some View {
        if let post = post,
           let postExcerptText = post.excerptText(configuration: .init(textLengthMax: 150,
                                                                       textLineMax: 3,
                                                                       imageCountMax: 0)) {
            Text(postExcerptText)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .lineLimit(2)
                .foregroundColor(.primary.opacity(0.6))
        }
    }

    @ViewBuilder
    func contentExcerptView() -> some View {
        switch notification.attributes.content {
        case .postLiked, .postReacted, .privateDiscussionCreated, .badgeReceived:
            EmptyView()
        case .postMentioned, .privateDiscussionReplied:
            if let replyExcerptText = replyExcerptText, replyExcerptText != "" {
                Text(replyExcerptText)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .lineLimit(2)
                    .foregroundColor(.primary.opacity(0.9))
            }
        }
    }
}
