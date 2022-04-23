//
//  FlarumPost.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/23.
//

import Foundation

struct FlarumPostAttributes: Decodable {
    enum FlarumPostContent {
        case comment(String)
        case discussionRenamed([[Int]])
        case discussionTagged([String])
        case discussionLocked(Bool)
    }

    enum FlarumPostContentType: String, RawRepresentable, Decodable {
        case comment
        case discussionRenamed
        case discussionTagged
        case discussionLocked
    }

    enum CodingKeys: String, CodingKey {
        case number
        case createdAt
        case contentType
        case contentHtml
        case canEdit
        case canDelete
        case canHide
        case canFlag
        case isApproved
        case canLike
        case canReact
    }

    var number: Int
    var createdAt: String
    var contentType: PostContentType
    var contentHtml: String?
    var content: FlarumPostContent? // Only available when login, and should be decoded manually.
    var canEdit: Bool?
    var canDelete: Bool?
    var canHide: Bool?
    var canFlag: Bool?
    var isApproved: Bool?
    var canLike: Bool?
    var canReact: Bool?

    var createdDate: Date? {
        // date format, example: 2022-03-23T13:37:49+00:00
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let dateString = createdAt.prefix(25)
        return dateFormatter.date(from: String(dateString))
    }
}

struct FlarumPostRelationships {
    enum Relationship: CaseIterable {
        case user
        case discussion
        case likes
        case reactions
        case mentionedBy
    }

    var user: FlarumUser?
    var discussion: FlarumDiscussion?
    var likes: [FlarumUser]?
    var reactions: [FlarumPostReaction]?
    var mentionedBy: [FlarumUser]?
}

class FlarumPost {
    init(id: String, attributes: FlarumPostAttributes? = nil, relationships: FlarumPostRelationships? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumPostAttributes?
    var relationships: FlarumPostRelationships?
}

extension FlarumPost: Equatable {
    static func == (lhs: FlarumPost, rhs: FlarumPost) -> Bool {
        lhs.id == rhs.id
    }
}
