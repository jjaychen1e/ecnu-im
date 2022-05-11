//
//  NotificationCenterView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/11.
//

import SwiftUI
import SwiftyJSON

private struct NotificationView: View {
    @State var notification: FlarumNotification
    @State var replyExcerptText: String?

    @Environment(\.splitVC) var splitVC

    var body: some View {
        let type = notification.attributes.contentType
        let post = notification.relationships?.subject
        let discussion = post?.relationships?.discussion
        let user = notification.relationships?.fromUser

        VStack(alignment: .leading, spacing: 6) {
            Text(discussion?.discussionTitle ?? "Unkown")
                .font(.system(size: 17, weight: .medium, design: .rounded))

            if let content = post?.attributes?.content,
               case let .comment(comment) = content {
                let parser = ContentParser(content: comment,
                                           configuration: .init(imageOnTapAction: { _, _ in },
                                                                imageGridDisplayMode: .narrow),
                                           updateLayout: nil)
                let postExcerptText = parser.getExcerptContent(configuration:
                    .init(textLengthMax: 150,
                          textLineMax: 3,
                          imageCountMax: 0)
                ).text

                Text(postExcerptText)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .lineLimit(2)
                    .foregroundColor(.primary.opacity(0.6))
            }

            HStack {
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
                }
                PostAuthorAvatarView(name: user?.attributes.displayName ?? "Unkown", url: user?.avatarURL, size: 30)
                (Text(user?.attributes.displayName ?? "Unkown") + Text(" \(type.description)了你"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
            }

            if case .postMentioned = notification.attributes.content {
                Text(replyExcerptText ?? "")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .lineLimit(2)
                    .foregroundColor(.primary.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(notification.attributes.isRead ? Color.clear : Color.gray)
        .onLoad {
            if case let .postMentioned(replyNumber) = notification.attributes.content {
                if let discussion = discussion,
                   let id = Int(discussion.id) {
                    Task {
                        if let response = try? await flarumProvider.request(.postsNearNumber(discussionID: id, nearNumber: replyNumber, limit: 4)) {
                            let json = JSON(response.data)
                            let flarumResponse = FlarumResponse(json: json)
                            let post = flarumResponse.data.posts.first { p in
                                p.attributes?.number == replyNumber
                            }
                            if let post = post {
                                if let content = post.attributes?.content,
                                   case let .comment(comment) = content {
                                    let parser = ContentParser(content: comment,
                                                               configuration: .init(imageOnTapAction: { _, _ in },
                                                                                    imageGridDisplayMode: .narrow),
                                                               updateLayout: nil)
                                    let postExcerptText = parser.getExcerptContent(configuration:
                                        .init(textLengthMax: 150,
                                              textLineMax: 3,
                                              imageCountMax: 0)
                                    ).text
                                    replyExcerptText = postExcerptText
                                }
                            }
                        }
                    }
                } else {
                    #if DEBUG
                        fatalError()
                    #endif
                }
            }
        }
        .onTapGesture {
            switch notification.attributes.content {
            case .postLiked, .postReacted:
                if AppGlobalState.shared.tokenPrepared {
                    if let post = post,
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
                    if let post = post,
                       let discussion = post.relationships?.discussion {
                        splitVC?.setSplitViewRoot(viewController: DiscussionViewController(discussion: discussion, nearNumber: replyNumber),
                                                  column: .secondary,
                                                  immediatelyShow: true)
                    }
                } else {
                    splitVC?.presentSignView()
                }
            }
        }
    }
}

struct NotificationCenterView: View {
    @State private var notifications: [FlarumNotification] = []

    var body: some View {
        List {
            ForEach(0 ..< notifications.count, id: \.self) { index in
                let notification = notifications[index]
                NotificationView(notification: notification)
            }
        }
        .listStyle(.plain)
        .onLoad {
            Task {
                if let response = try? await flarumProvider.request(.notification(offset: 0, limit: 30)) {
                    let json = JSON(response.data)
                    let flarumResponse = FlarumResponse(json: json)
                    self.notifications = flarumResponse.data.notifications
                }
            }
        }
    }
}

struct NotificationCenterView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationCenterView()
    }
}
