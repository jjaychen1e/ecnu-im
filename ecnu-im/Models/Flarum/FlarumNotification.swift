//
//  FlarumNotification.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/10.
//

import Foundation

struct FlarumNotificationAttributes: Codable {
    enum FlarumNotificationContent: Codable {
        case postLiked
        case postMentioned(replyNumber: Int)
        case postReacted(reaction: FlarumReaction)
        case privateDiscussionReplied(postNumber: Int)
        case privateDiscussionCreated
    }

    enum FlarumNotificationContentType: String, RawRepresentable, Codable {
        case postLiked
        case postMentioned
        case postReacted
        case privateDiscussionReplied = "byobuPrivateDiscussionReplied"
        case privateDiscussionCreated = "byobuPrivateDiscussionCreated"

        var description: String {
            switch self {
            case .postLiked:
                return "喜欢"
            case .postMentioned:
                return "回复"
            case .postReacted:
                return "戳"
            case .privateDiscussionReplied:
                return "在私密主题中回复"
            case .privateDiscussionCreated:
                return "在私密主题中邀请"
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
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let dateString = createdAt.prefix(25)
        return dateFormatter.date(from: String(dateString))
    }
}

struct FlarumNotificationRelationships {
    enum Subject {
        case post(post: FlarumPost)
        case discussion(discussion: FlarumDiscussion)
    }

    enum SubjectType: String, RawRepresentable {
        case post = "posts"
        case discussion = "discussions"
    }

    var fromUser: FlarumUser
    var subject: Subject
}

class FlarumNotification {
    init(id: String, attributes: FlarumNotificationAttributes, relationships: FlarumNotificationRelationships? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
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
        case .none:
            return nil
        }
    }

    var originalPost: FlarumPost? {
        switch relationships?.subject {
        case let .post(post):
            return post
        case let .discussion(discussion):
            return discussion.firstPost
        case .none:
            return nil
        }
    }
}
