//
//  Post.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/26.
//

import Foundation
import SwiftSoup

enum PostContentType: String, RawRepresentable, Decodable {
    case comment
}

struct PostAttribute: Decodable {
    var number: Int
    var createdAt: String
    var contentType: PostContentType
    var contentHtml: String

    var createdDate: Date? {
        // date format, exmaple: 2022-03-23T13:37:49+00:00
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let dateString = createdAt.prefix(25)
        return dateFormatter.date(from: String(dateString))
    }
}

struct PostRelationship: Decodable {
    var user: String
    var discussion: String
    var likes: [String] = [] // User id
    var reactions: [String] = [] // post_reactions id
    var mentionedBy: [String] = [] // Post id

    init(user: String, discussion: String, likes: [String] = [], reactions: [String] = [], mentionedBy: [String] = []) {
        self.user = user
        self.discussion = discussion
        self.likes = likes
        self.reactions = reactions
        self.mentionedBy = mentionedBy
    }

    init(user: String, discussion: String) {
        self.user = user
        self.discussion = discussion
    }
}

struct LoadMoreState {
    var prevOffset: Int?
    var nextOffset: Int?
}

struct Post: Decodable, Identifiable {
    var id: String
    var attributes: PostAttribute?
    var relationships: PostRelationship?

    // Filter out includedUsers, includedPosts in CodingKeys
    // Because we need to decode them manually
    enum CodingKeys: String, CodingKey {
        case id
        case attributes
        case relationships
    }

    var includedUsers: [User] = []
    var includedPosts: [Post] = []

    var loadMoreState: LoadMoreState?
    var isDeleted: Bool?

    var contentHtmlElements: Elements? {
        if let html = attributes?.contentHtml {
            let parser = ContentHtmlParser()
            return parser.parse(html)
        }
        return nil
    }

    // Extension can not have stored property
    var postContentViews: [Any] {
        if let elements = contentHtmlElements {
            let converter = ContentHtmlViewConverter()
            return converter.convert(elements)
        }

        return []
    }
}

extension Post {
    var author: User? {
        includedUsers.first { $0.id == relationships?.user }
    }

    var authorName: String {
        author?.attributes?.displayName ?? "Unkown"
    }

    var authorAvatarURL: URL? {
        if let urlStr = author?.attributes?.avatarUrl {
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
}

extension Post: Equatable {
    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }
}
