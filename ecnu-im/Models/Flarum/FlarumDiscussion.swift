//
//  FlarumDiscussion.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/23.
//

import Foundation

struct FlarumDiscussionAttributes: Decodable {
    var title: String
    var commentCount: Int?
    var participantCount: Int?
    var createdAt: String?
    var lastPostedAt: String?
    var lastPostNumber: Int?
    var canReply: Bool?
    var canRename: Bool?
    var canDelete: Bool?
    var canHide: Bool?
    var isHidden: Bool?
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

struct FlarumDiscussionRelationshipsReference {
    enum Relationship: CaseIterable {
        case user
        case lastPostedUser
        case firstPost
        case lastPost
        case mostRelevantPost
        case tags
    }

    weak var user: FlarumUserReference?
    weak var lastPostedUser: FlarumUserReference?
    weak var firstPost: FlarumPostReference?
    weak var lastPost: FlarumPostReference?
    weak var mostRelevantPost: FlarumPostReference?
    @Weak var tags: [FlarumTagReference]
}

class FlarumDiscussionReference {
    init(id: String, attributes: FlarumDiscussionAttributes? = nil, relationships: FlarumDiscussionRelationshipsReference? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumDiscussionAttributes?
    var relationships: FlarumDiscussionRelationshipsReference?
}

extension Array where Element == FlarumTag {
    var mappedTagViewModels: [TagViewModel] {
        var tagViewModels: [TagViewModel] = []
        let subTags = filter { $0.attributes.isChild }
        let firstLevelTags = filter { !$0.attributes.isChild }
        for tag in firstLevelTags {
            let tagViewModel = TagViewModel(tag: tag)
            if let childTag = subTags.first(where: { $0.relationships?.parent?.id == tag.id }) {
                tagViewModel.child = TagViewModel(tag: childTag)
            }
            tagViewModels.append(tagViewModel)
        }

        return tagViewModels
    }
}

struct FlarumDiscussionRelationships {
    enum Relationship: CaseIterable {
        case user
        case lastPostedUser
        case firstPost
        case lastPost
        case mostRelevantPost
        case tags
    }

    var user: FlarumUser?
    var lastPostedUser: FlarumUser?
    var firstPost: FlarumPost?
    var lastPost: FlarumPost?
    var mostRelevantPost: FlarumPost?
    var tags: [FlarumTag]?

    init(_ i: FlarumDiscussionRelationshipsReference) {
        user = i.user != nil ? .init(i.user!) : nil
        lastPostedUser = i.lastPostedUser != nil ? .init(i.lastPostedUser!) : nil
        firstPost = i.firstPost != nil ? .init(i.firstPost!) : nil
        lastPost = i.lastPost != nil ? .init(i.lastPost!) : nil
        mostRelevantPost = i.mostRelevantPost != nil ? .init(i.mostRelevantPost!) : nil
        tags = i.tags.map { FlarumTag($0) }
    }
}

struct FlarumDiscussion {
    init(id: String, attributes: FlarumDiscussionAttributes? = nil, relationships: FlarumDiscussionRelationships? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumDiscussionAttributes?
    var relationships: FlarumDiscussionRelationships?

    init(_ i: FlarumDiscussionReference) {
        id = i.id
        attributes = i.attributes
        relationships = i.relationships != nil ? .init(i.relationships!) : nil
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

    var mostRelevantPost: FlarumPost? {
        relationships?.mostRelevantPost
    }

    var mostRelevantPostUser: FlarumUser? {
        mostRelevantPost?.author
    }

    var lastPostedUser: FlarumUser? {
        relationships?.lastPostedUser
    }

    var tags: [FlarumTag] {
        relationships?.tags ?? []
    }

    var tagViewModels: [TagViewModel] {
        tags.mappedTagViewModels
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

    var mostRelevantPostedUserName: String {
        "@" + (mostRelevantPostUser?.attributes.displayName ?? "Unkown")
    }

    var mostRelevantPostUserAvatarURL: URL? {
        if let urlString = mostRelevantPostUser?.attributes.avatarUrl {
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

    var commentCount: Int {
        attributes?.commentCount ?? 0
    }

    var viewCount: Int {
        attributes?.viewCount ?? 0
    }

    var isHidden: Bool {
        attributes?.isHidden ?? false
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
