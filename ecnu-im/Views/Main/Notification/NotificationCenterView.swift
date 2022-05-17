//
//  NotificationCenterView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/11.
//

import Combine
import SwiftUI
import SwiftyJSON

private struct NotificationView: View {
    @State var notification: FlarumNotification
    @State var badgeNotificationTitle: String?
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

                Text(notification.createdDateDescription)
                    .font(.system(size: 13, weight: .light, design: .rounded))
            }

            repliedPostExcerptView()
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
                            withAnimation {
                                badgeNotificationTitle = "你获得了一个新徽章: \(badge.description)！"
                            }
                        } else {
                            // We need to fetch from user's api
                            Task {
                                if let id = AppGlobalState.shared.userIdInt {
                                    if let response = try? await flarumProvider.request(.user(id: id)).flarumResponse() {
                                        let userBadges = response.included.userBadges
                                        FlarumBadgeStorage.shared.store(userBadges: userBadges)
                                        if let userBadge = FlarumBadgeStorage.shared.userBadge(for: userBadgeId),
                                           let badge = userBadge.relationships?.badge {
                                            withAnimation {
                                                badgeNotificationTitle = "你获得了一个新徽章: \(badge.description)！"
                                            }
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
                    uiKitEnvironment.splitVC?.presentSignView()
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
                    uiKitEnvironment.splitVC?.presentSignView()
                }
            case .badgeReceived:
                // TODO: Badge - Jump to profile?
                break
            case let .privateDiscussionReplied(postNumber):
                if AppGlobalState.shared.tokenPrepared {
                    if let post = originalPost,
                       let discussion = post.relationships?.discussion {
                        uiKitEnvironment.splitVC?.push(viewController: DiscussionViewController(discussion: discussion, nearNumber: postNumber),
                                                       column: .secondary,
                                                       toRoot: true)
                    }
                } else {
                    uiKitEnvironment.splitVC?.presentSignView()
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
                    uiKitEnvironment.splitVC?.presentSignView()
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
            Image(fa: .award, faStyle: .solid, color: .orange)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25, height: 25)
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
    func repliedPostExcerptView() -> some View {
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

struct NotificationCenterView: View {
    @State private var notifications: [FlarumNotification] = []
    @State private var subscriptions: Set<AnyCancellable> = []
    @State var hasScrolled = false
    @State private var loadTask: Task<Void, Never>? = nil

    var body: some View {
        Group {
            if notifications.count > 0 {
                List {
                    ForEach(0 ..< notifications.count, id: \.self) { index in
                        let notification = notifications[index]
                        NotificationView(notification: notification)
                            .listRowInsets(EdgeInsets())
                            .background(
                                Group {
                                    if index == 0 {
                                        scrollDetector
                                    }
                                },
                                alignment: .topLeading
                            )
                    }
                }
                .listStyle(.plain)
                .coordinateSpace(name: "scroll")
            } else {
                Color.clear
            }
        }
        .safeAreaInset(edge: .top) {
            header
        }
        .onLoad {
            load()
            AppGlobalState.shared.$tokenPrepared.sink { change in
                load()
            }.store(in: &subscriptions)
        }
    }

    func load() {
        loadTask?.cancel()
        loadTask = nil
        notifications = []
        loadTask = Task {
            if let response = try? await flarumProvider.request(.notification(offset: 0, limit: 30)).flarumResponse() {
                guard !Task.isCancelled else { return }
                self.notifications = response.data.notifications
            }
        }
    }

    var scrollDetector: some View {
        GeometryReader { proxy in
            Color.clear.preference(key: ScrollPreferenceKey.self, value: proxy.frame(in: .named("scroll")).minY)
        }
        .onPreferenceChange(ScrollPreferenceKey.self) { value in
            withAnimation(.easeInOut(duration: 0.3)) {
                if value < 70 {
                    hasScrolled = true
                } else {
                    hasScrolled = false
                }
            }
        }
        .frame(height: 0)
    }

    var header: some View {
        ZStack {
            Text("通知中心")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.teal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                .padding(.top, 20)

            Button {} label: {
                HStack(spacing: 16) {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.bold))
                        .frame(width: 36, height: 36)
                        .foregroundColor(.secondary)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .modifier(OutlineOverlay(cornerRadius: 14))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 20)
                .padding(.top, 20)
            }
        }
        .background(
            Color.clear
                .background(.ultraThinMaterial)
                .blur(radius: 10)
                .opacity(hasScrolled ? 1 : 0)
        )
        .frame(alignment: .top)
    }
}

struct NotificationCenterView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationCenterView()
    }
}
