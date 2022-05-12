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
    @State var replyExcerptText: String?

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.splitVC) var splitVC

    var body: some View {
        let type = notification.attributes.contentType
        let relatedDiscussion = notification.relatedDiscussion
        let originalPost = notification.originalPost
        let user = notification.relationships?.fromUser

        VStack(alignment: .leading, spacing: 6) {
            Text(relatedDiscussion?.discussionTitle ?? "Unkown")
                .font(.system(size: 17, weight: .medium, design: .rounded))

            originalPostExcerptView(post: originalPost)

            HStack {
                iconView(type: type)

                PostAuthorAvatarView(name: user?.attributes.displayName ?? "Unkown", url: user?.avatarURL, size: 30)
                (Text(user?.attributes.displayName ?? "Unkown") + Text(" \(type.description)了你"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                Text(notification.createdDateDescription)
                    .font(.system(size: 13, weight: .light, design: .rounded))
            }

            repliedPostExcerptView()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.all, 8)
        .background(notification.attributes.isRead ? Color.clear : colorScheme == .light ? Color(rgba: "#e4ebf6") : Color(rgba: "#e4ebf6").opacity(0.2))
        .onLoad {
            Task {
                if let repliedPost = await notification.repliedPost() {
                    replyExcerptText = repliedPost.excerptText(configuration: .init(textLengthMax: 150,
                                                                                    textLineMax: 3,
                                                                                    imageCountMax: 0))
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
                        splitVC?.setSplitViewRoot(viewController: DiscussionViewController(discussion: discussion, nearNumber: number),
                                                  column: .secondary,
                                                  immediatelyShow: true)
                    }
                } else {
                    splitVC?.presentSignView()
                }
            case let .postMentioned(replyNumber):
                if AppGlobalState.shared.tokenPrepared {
                    if let post = originalPost,
                       let discussion = post.relationships?.discussion {
                        splitVC?.setSplitViewRoot(viewController: DiscussionViewController(discussion: discussion, nearNumber: replyNumber),
                                                  column: .secondary,
                                                  immediatelyShow: true)
                    }
                } else {
                    splitVC?.presentSignView()
                }
            case let .privateDiscussionReplied(postNumber):
                if AppGlobalState.shared.tokenPrepared {
                    if let post = originalPost,
                       let discussion = post.relationships?.discussion {
                        splitVC?.setSplitViewRoot(viewController: DiscussionViewController(discussion: discussion, nearNumber: postNumber),
                                                  column: .secondary,
                                                  immediatelyShow: true)
                    }
                } else {
                    splitVC?.presentSignView()
                }
            case .privateDiscussionCreated:
                if AppGlobalState.shared.tokenPrepared {
                    if let post = originalPost,
                       let discussion = post.relationships?.discussion {
                        splitVC?.setSplitViewRoot(viewController: DiscussionViewController(discussion: discussion, nearOffset: 0),
                                                  column: .secondary,
                                                  immediatelyShow: true)
                    }
                } else {
                    splitVC?.presentSignView()
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
        case .postLiked, .postReacted, .privateDiscussionCreated:
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

    var body: some View {
        Group {
            if notifications.count > 0 {
                List {
                    ForEach(0 ..< notifications.count, id: \.self) { index in
                        let notification = notifications[index]
                        NotificationView(notification: notification)
                            .listRowInsets(EdgeInsets())
                    }
                }
                .listStyle(.plain)
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
        Task {
            if let response = try? await flarumProvider.request(.notification(offset: 0, limit: 30)) {
                let json = JSON(response.data)
                let flarumResponse = FlarumResponse(json: json)
                self.notifications = flarumResponse.data.notifications
            }
        }
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
//                .opacity(hasScrolled ? 1 : 0)
        )
        .frame(alignment: .top)
    }
}

struct NotificationCenterView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationCenterView()
    }
}
