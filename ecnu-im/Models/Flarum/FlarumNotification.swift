//
//  FlarumNotification.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/10.
//

import Foundation
import SwiftyJSON

struct FlarumNotificationAttributes: Codable {
    enum FlarumNotificationContent: Codable {
        case postLiked
        case postMentioned(replyNumber: Int)
        case userMentioned
        case postReacted(reaction: FlarumReaction)
        case badgeReceived
        case newPost(postNumber: Int)
        case privateDiscussionReplied(postNumber: Int)
        case privateDiscussionCreated
        case privateDiscussionAdded
    }

    enum FlarumNotificationContentType: String, RawRepresentable, Codable {
        case postLiked
        case postMentioned
        case userMentioned
        case postReacted
        case badgeReceived
        case newPost
        case privateDiscussionReplied = "byobuPrivateDiscussionReplied"
        case privateDiscussionCreated = "byobuPrivateDiscussionCreated"
        case privateDiscussionAdded = "byobuPrivateDiscussionAdded"

        var actionDescription: String {
            switch self {
            case .postLiked:
                return "喜欢了你"
            case .postMentioned:
                return "回复了你"
            case .userMentioned:
                return "提到了你"
            case .postReacted:
                return "戳了你"
            case .badgeReceived:
                return ""
            case .newPost:
                return "发表了新的回复"
            case .privateDiscussionReplied:
                return "在私密主题中回复了你"
            case .privateDiscussionCreated:
                return "在私密主题中邀请了你"
            case .privateDiscussionAdded:
                return "在私密主题中邀请了你"
            }
        }
    }

    var contentType: FlarumNotificationContentType
    var content: FlarumNotificationContent
    var createdAt: String
    var isRead: Bool

    var createdDate: Date? {
        // date format, example: 2022-03-23T13:37:49+00:00
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .init(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let dateString = createdAt.prefix(25)
        return dateFormatter.date(from: String(dateString))
    }
}

struct FlarumNotificationRelationshipsReference {
    enum Subject {
        case post(post: FlarumPostReference)
        case discussion(discussion: FlarumDiscussionReference)
        case userBadge(userBadgeId: Int)
    }

    enum SubjectType: String, RawRepresentable {
        case post = "posts"
        case discussion = "discussions"
        case userBadge = "userBadges"
    }

    unowned var fromUser: FlarumUserReference?
    // TODO: enum should have another struct layer to add weak
    var subject: Subject
}

class FlarumNotificationReference {
    init(id: String, attributes: FlarumNotificationAttributes, relationships: FlarumNotificationRelationshipsReference? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumNotificationAttributes
    var relationships: FlarumNotificationRelationshipsReference?
}

struct FlarumNotificationRelationships {
    enum Subject {
        case post(post: FlarumPost)
        case discussion(discussion: FlarumDiscussion)
        case userBadge(userBadgeId: Int)

        init(_ i: FlarumNotificationRelationshipsReference.Subject) {
            switch i {
            case let .discussion(discussion):
                self = .discussion(discussion: .init(discussion))
                return
            case let .post(post):
                self = .post(post: .init(post))
                return
            case let .userBadge(userBadgeId):
                self = .userBadge(userBadgeId: userBadgeId)
                return
            }
        }
    }

    enum SubjectType: String, RawRepresentable {
        case post = "posts"
        case discussion = "discussions"
        case userBadge = "userBadges"
    }

    var fromUser: FlarumUser?
    var subject: Subject

    init(_ i: FlarumNotificationRelationshipsReference) {
        subject = .init(i.subject)
        fromUser = i.fromUser != nil ? .init(i.fromUser!) : nil
    }
}

struct FlarumNotification {
    init(id: String, attributes: FlarumNotificationAttributes, relationships: FlarumNotificationRelationships? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    init(_ i: FlarumNotificationReference) {
        id = i.id
        attributes = i.attributes
        relationships = i.relationships != nil ? .init(i.relationships!) : nil
    }

    var id: String
    var attributes: FlarumNotificationAttributes
    var relationships: FlarumNotificationRelationships?

    var createdDateDescription: String {
        if let date = attributes.createdDate {
            return date.localeDescription
        } else {
            return "Unknown"
        }
    }

    var relatedDiscussion: FlarumDiscussion? {
        switch relationships?.subject {
        case let .post(post):
            return post.relationships?.discussion
        case let .discussion(discussion):
            return discussion
        case .userBadge, .none:
            return nil
        }
    }

    var originalPost: FlarumPost? {
        switch attributes.content {
        case .badgeReceived, .postLiked, .postMentioned, .postReacted, .privateDiscussionCreated, .privateDiscussionAdded, .privateDiscussionReplied:
            switch relationships?.subject {
            case let .post(post):
                return post
            case let .discussion(discussion):
                return discussion.firstPost
            case .userBadge, .none:
                return nil
            }
        case .userMentioned, .newPost:
            return nil
        }
    }

    func newPost() async -> FlarumPost? {
        var targetPostNumber: Int?
        var targetPost: FlarumPost?
        switch attributes.content {
        case .postLiked, .postReacted, .badgeReceived:
            break
        case let .postMentioned(replyNumber):
            targetPostNumber = replyNumber
        case let .newPost(postNumber):
            targetPostNumber = postNumber
        case let .privateDiscussionReplied(postNumber):
            targetPostNumber = postNumber
        case .userMentioned:
            if let subject = relationships?.subject {
                if case let .post(post) = subject {
                    targetPost = post
                }
            }
        case .privateDiscussionAdded, .privateDiscussionCreated:
            targetPostNumber = 1
        }

        if let targetPost = targetPost {
            return targetPost
        }

        if let targetPostNumber = targetPostNumber,
           let discussion = relatedDiscussion,
           let id = Int(discussion.id) {
            if let response = try? await flarumProvider.request(.postsNearNumber(discussionID: id, nearNumber: targetPostNumber, limit: 4)).flarumResponse() {
                let post = response.data.posts.first { p in
                    p.attributes?.number == targetPostNumber
                }
                return post
            }
        }

        return nil
    }
}

extension FlarumNotification: Hashable {
    static func == (lhs: FlarumNotification, rhs: FlarumNotification) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
