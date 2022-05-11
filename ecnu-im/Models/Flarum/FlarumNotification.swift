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
    }

    enum FlarumNotificationContentType: String, RawRepresentable, Codable {
        case postLiked
        case postMentioned
        case postReacted
        
        var description: String {
            switch self {
            case .postLiked:
                return "喜欢"
            case .postMentioned:
                return "回复"
            case .postReacted:
                return "戳"
            }
        }
    }

    var contentType: FlarumNotificationContentType
    var content: FlarumNotificationContent
    var createdAt: String
    var isRead: Bool
}

struct FlarumNotificationRelationships {
    var fromUser: FlarumUser
    var subject: FlarumPost // ?
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
}
