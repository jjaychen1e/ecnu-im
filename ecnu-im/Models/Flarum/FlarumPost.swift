//
//  FlarumPost.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/23.
//

import Foundation
import UIKit

struct FlarumPostAttributes: Decodable {
    enum FlarumPostContent: Decodable {
        case comment(String)
        case discussionRenamed([String])
        case discussionTagged([[Int]])
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
        case editedAt
        case contentType
        case contentHtml
        case content
        case canEdit
        case canDelete
        case canHide
        case isHidden
        case canFlag
        case isApproved
        case canLike
        case canReact
    }

    var number: Int? // Possible nil
    var createdAt: String
    var editedAt: String?
    var contentType: FlarumPostContentType?
    var contentHtml: String?
    var content: FlarumPostContent? // Only available when login, and should be decoded manually.
    var canEdit: Bool?
    var canDelete: Bool?
    var canHide: Bool?
    var isHidden: Bool?
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

    var editedDate: Date? {
        // date format, example: 2022-03-23T13:37:49+00:00
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let dateString = editedAt?.prefix(25) {
            return dateFormatter.date(from: String(dateString))
        }
        return nil
    }
}

struct FlarumPostRelationshipsReference {
    enum Relationship: CaseIterable {
        case user
        case discussion
        case likes
        case reactions
        case mentionedBy
    }

    var user: FlarumUserReference?
    var discussion: FlarumDiscussionReference?
    var likes: [FlarumUserReference]?
    var reactions: [FlarumPostReactionReference]?
    var mentionedBy: [FlarumPostReference]?
}

class FlarumPostReference {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    init(id: String, attributes: FlarumPostAttributes? = nil, relationships: FlarumPostRelationshipsReference? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumPostAttributes?
    var relationships: FlarumPostRelationshipsReference?
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
    var likes: [FlarumUser]?
    var reactions: [FlarumPostReaction]?
    var mentionedBy: [FlarumPost]?
    private var boxedDiscussion: Box<FlarumDiscussion>?

    var discussion: FlarumDiscussion? {
        boxedDiscussion?.value
    }

    init(_ i: FlarumPostRelationshipsReference) {
        user = i.user != nil ? .init(i.user!) : nil
        boxedDiscussion = i.discussion != nil ? .init(value: .init(i.discussion!)) : nil
        likes = i.likes?.map { .init($0) }
    }
}

struct FlarumPost: Hashable {
    static func == (lhs: FlarumPost, rhs: FlarumPost) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    init(id: String, attributes: FlarumPostAttributes? = nil, relationships: FlarumPostRelationships? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    init(_ i: FlarumPostReference) {
        id = i.id
        attributes = i.attributes
        relationships = i.relationships != nil ? .init(i.relationships!) : nil
    }

    var id: String
    var attributes: FlarumPostAttributes?
    var relationships: FlarumPostRelationships?

    // MARK: Loading Logic

    struct FlarumPostLoadMoreState {
        var prevOffset: Int?
        var nextOffset: Int?
    }

    // Excerpt Text
    func excerptText(configuration: ContentParser.ContentExcerpt.ContentExcerptConfiguration) -> String? {
        if let content = attributes?.content,
           case let .comment(comment) = content {
            let parser = ContentParser(content: comment,
                                       configuration: .init(imageOnTapAction: { _, _ in },
                                                            imageGridDisplayMode: .narrow),
                                       updateLayout: nil)
            let postExcerptText = parser.getExcerptContent(configuration: configuration).text
            return postExcerptText
        }
        return nil
    }
}

extension FlarumPost {
    var author: FlarumUser? {
        relationships?.user
    }

    var authorName: String {
        author?.attributes.displayName ?? "Unkown"
    }

    var authorAvatarURL: URL? {
        if let urlStr = author?.attributes.avatarUrl {
            return URL(string: urlStr)
        }
        return nil
    }

    var createdDateDescription: String {
        if let date = attributes?.createdDate {
            return date.localeDescription
        } else {
            return "Unknown"
        }
    }

    var editedDateDescription: String? {
        if let date = attributes?.editedDate {
            return date.localeDescription
        } else {
            return nil
        }
    }

    var isHidden: Bool {
        attributes?.isHidden ?? false
    }

    var discussion: FlarumDiscussion? {
        relationships?.discussion ?? nil
    }

    var discussionAuthor: FlarumUser? {
        discussion?.starter
    }
}
