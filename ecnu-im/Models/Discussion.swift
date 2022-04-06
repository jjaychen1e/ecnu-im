//
//  Discussion.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/26.
//

import Foundation

struct DiscussionAttributes: Decodable {
    var title: String
    var commentCount: Int
    var participantCount: Int?
    var createdAt: String?
    var lastPostedAt: String?
    var lastPostNumner: Int?
    var canReply: Bool?
    var canRename: Bool?
    var canDevare: Bool?
    var canHide: Bool?
    var lastReadAt: String?
    var lastReadPostNumber: Int?
    var isApproved: Bool?
    var isSticky: Bool?
    var canSticky: Bool?
    var canTag: Bool?
    var isSticktiest: Bool?
    var canTagSticky: Bool?
    var canReset: Bool?
    var viewCount: Int?
    var canViewNumber: Bool?
    var canSeeReactions: Bool?
    var canMerge: Bool?
    var canEditRecipients: Bool?
    var canEditUserRecipients: Bool?
    var canEditGroupRecipients: Bool?
    var isPrivateDiscussion: Bool?
    var isLocked: Bool?
    var canLock: Bool?

    var createdDate: Date? {
        // date format, exmaple: 2022-03-23T13:37:49+00:00
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let dateString = createdAt?.prefix(25) {
            return dateFormatter.date(from: String(dateString))
        }
        return nil
    }

    var lastPostDate: Date? {
        // date format, exmaple: 2022-03-23T13:37:49+00:00
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let dateString = lastPostedAt?.prefix(25) {
            return dateFormatter.date(from: String(dateString))
        }
        return nil
    }

    var lastReadDate: Date? {
        // date format, exmaple: 2022-03-23T13:37:49+00:00
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let dateString = lastReadAt?.prefix(25) {
            return dateFormatter.date(from: String(dateString))
        }
        return nil
    }
}

struct DiscussionRelationship: Decodable {
    var user: String?
    var lastPostedUser: String?
    var firstPost: String?
    var lastPost: String?
    var tags: [String]?
    var recipientUsers: [String]?
    var recipientGroups: [String]?
}

// TODO: Move included info into another data structure
struct Discussion: Decodable {
    var id: String
    var attributes: DiscussionAttributes?
    var relationships: DiscussionRelationship?

    var includedUsers: [User] = []
    var includedPosts: [Post] = []
    var includedTags: [Tag] = []

    // Filter out includedUsers, includedPosts, includedTags in CodingKeys
    // Because we need to decode them manually
    enum CodingKeys: String, CodingKey {
        case id
        case attributes
        case relationships
    }

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

extension Discussion: Identifiable, Hashable {
    static func == (lhs: Discussion, rhs: Discussion) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Discussion {
    var starter: User? {
        includedUsers.first { $0.id == relationships?.user }
    }

    var firstPost: Post? {
        includedPosts.first { $0.id == relationships?.firstPost }
    }

    var lastPost: Post? {
        includedPosts.first { $0.id == relationships?.lastPost }
    }

    var lastPostedUser: User? {
        includedUsers.first { $0.id == relationships?.lastPostedUser }
    }

    var tags: [Tag] {
        includedTags.filter { relationships?.tags?.contains($0.id) ?? false }
    }

    var synthesisedTag: TagViewModel? {
        if tags.count == 1 {
            return TagsViewModel.shared.allTags.first { $0.id == tags.first!.id }
        } else {
            // Parent-Child, or 精品
            // We should change the logic.. thses codes are shit.
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
        "@" + (starter?.attributes?.displayName ?? "Unkown")
    }

    var starterAvatarURL: URL? {
        if let urlString = starter?.attributes?.avatarUrl {
            return URL(string: urlString)
        }
        return nil
    }

    var lastPostedUserName: String {
        "@" + (lastPostedUser?.attributes?.displayName ?? "Unkown")
    }

    var lastPostedUserAvatarURL: URL? {
        if let urlString = lastPostedUser?.attributes?.avatarUrl {
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
