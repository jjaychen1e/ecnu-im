//
//  FlarumDiscussion.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/23.
//

import Foundation

struct FlarumDiscussionAttributes: Decodable {
    var title: String
    var commentCount: Int
    var participantCount: Int?
    var createdAt: String?
    var lastPostedAt: String?
    var lastPostNumber: Int?
    var canReply: Bool?
    var canRename: Bool?
    var canDelete: Bool?
    var canHide: Bool?
    var lastReadAt: String?
    var lastReadPostNumber: Int?
    var isApproved: Bool?
    var isSticky: Bool?
    var canSticky: Bool?
    var canTag: Bool?
    var isPrivateDiscussion: Bool?
    var isStickiest: Bool?
    var isTagSticky: Bool?
    var canStickiest: Bool?
    var canTagSticky: Bool?
    var canReset: Bool?
    var viewCount: Int?
    var canViewNumber: Bool?
    var canSeeReactions: Bool?
    var canMerge: Bool?
    var canEditRecipients: Bool?
    var canEditUserRecipients: Bool?
    var canEditGroupRecipients: Bool?
    var isLocked: Bool?
    var canLock: Bool?

    var createdDate: Date? {
        // date format, example: 2022-03-23T13:37:49+00:00
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let dateString = createdAt?.prefix(25) {
            return dateFormatter.date(from: String(dateString))
        }
        return nil
    }

    var lastPostDate: Date? {
        // date format, example: 2022-03-23T13:37:49+00:00
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let dateString = lastPostedAt?.prefix(25) {
            return dateFormatter.date(from: String(dateString))
        }
        return nil
    }

    var lastReadDate: Date? {
        // date format, example: 2022-03-23T13:37:49+00:00
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let dateString = lastReadAt?.prefix(25) {
            return dateFormatter.date(from: String(dateString))
        }
        return nil
    }
}

struct FlarumDiscussionRelationships {
    enum Relationship: CaseIterable {
        case user
        case lastPostedUser
        case firstPost
        case lastPost
        case tags
    }

    var user: FlarumUser?
    var lastPostedUser: FlarumUser?
    var firstPost: FlarumPost?
    var lastPost: FlarumPost?
    var tags: [FlarumTag]?
}

class FlarumDiscussion {
    init(id: String, attributes: FlarumDiscussionAttributes? = nil, relationships: FlarumDiscussionRelationships? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumDiscussionAttributes?
    var relationships: FlarumDiscussionRelationships?

    // Extension can not have stored property
    var firstPostContentExcerptViews: [Any] {
        if let html = firstPost?.attributes?.contentHtml {
            let parser = ContentHtmlParser()
            if let elements = parser.parse(html) {
                let converter = ContentHtmlViewConverter(elementCountLimit: 5, textLengthLimit: 100, mode: .excerpt)
                return converter.convert(elements)
            }
        }

        return []
    }

    // Extension can not have stored property
    var lastPostContentExcerptViews: [Any] {
        if let html = lastPost?.attributes?.contentHtml {
            let parser = ContentHtmlParser()
            if let elements = parser.parse(html) {
                let converter = ContentHtmlViewConverter(elementCountLimit: 5, textLengthLimit: 100, mode: .excerpt)
                return converter.convert(elements)
            }
        }

        return []
    }
}

extension FlarumDiscussion {
    var starter: FlarumUser? {
        relationships?.user
    }

    var firstPost: FlarumPost? {
        relationships?.firstPost
    }

    var lastPost: FlarumPost? {
        relationships?.lastPost
    }

    var lastPostedUser: FlarumUser? {
        relationships?.lastPostedUser
    }

    var tags: [FlarumTag] {
        relationships?.tags ?? []
    }

    var synthesizedTag: TagViewModel? {
        if tags.count == 1 {
            return TagsViewModel.shared.allTags.first { $0.id == tags.first!.id }
        } else {
            // Parent-Child, or 精品
            // We should change the logic.. theses codes are shit.
            for possibleParentTag in tags {
                if TagsViewModel.shared.allParentTags.contains(where: { $0.id == possibleParentTag.id }) {
                    return TagsViewModel.shared.allTags.first { parent in
                        possibleParentTag.id == parent.id && parent.child != nil && tags.contains(where: { t in t.id == parent.child!.id })
                    }
                }
            }
        }
        return nil
    }

    var discussionTitle: String {
        attributes?.title ?? "Unkown"
    }

    var starterName: String {
        "@" + (starter?.attributes.displayName ?? "Unkown")
    }

    var starterAvatarURL: URL? {
        if let urlString = starter?.attributes.avatarUrl {
            return URL(string: urlString)
        }
        return nil
    }

    var lastPostedUserName: String {
        "@" + (lastPostedUser?.attributes.displayName ?? "Unkown")
    }

    var lastPostedUserAvatarURL: URL? {
        if let urlString = lastPostedUser?.attributes.avatarUrl {
            return URL(string: urlString)
        }
        return nil
    }

    var firstPostDateDescription: String {
        if let date = firstPost?.attributes?.createdDate {
            return date.localeDescription
        } else {
            return "Unknown"
        }
    }

    var lastPostDateDescription: String {
        if let date = lastPost?.attributes?.createdDate {
            return date.localeDescription
        } else {
            return "Unknown"
        }
    }
}

extension FlarumDiscussion: Hashable {
    static func == (lhs: FlarumDiscussion, rhs: FlarumDiscussion) -> Bool {
        let condition1 = lhs.id == rhs.id
        let condition2 = lhs.firstPost?.id == rhs.firstPost?.id
        let condition3 = lhs.lastPost?.id == rhs.lastPost?.id
        let condition4 = lhs.firstPost?.attributes?.contentHtml == rhs.firstPost?.attributes?.contentHtml
        let condition5 = lhs.lastPost?.attributes?.contentHtml == rhs.lastPost?.attributes?.contentHtml
        return condition1 && condition2 && condition3 && condition4 && condition5
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        if let lastPostID = lastPost?.id {
            hasher.combine(lastPostID)
        }
        if let firstPostID = firstPost?.id {
            hasher.combine(firstPostID)
        }
        if let firstPostContentHtml = firstPost?.attributes?.contentHtml {
            hasher.combine(firstPostContentHtml)
        }
        if let lastPostContentHtml = lastPost?.attributes?.contentHtml {
            hasher.combine(lastPostContentHtml)
        }
    }
}
