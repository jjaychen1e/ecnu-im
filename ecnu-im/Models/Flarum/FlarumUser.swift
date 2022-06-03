//
//  FlarumUser.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/23.
//

import Foundation
import UIKit

struct FlarumUserAttributes: Codable {
    var username: String
    var displayName: String
    var avatarUrl: String?
    var lastSeenAt: String?
    var joinTime: String?
    var slug: String
    var bio: String?
    var likesReceived: Int?
    var commentCount: Int?
    var discussionCount: Int?
    var ignored: Bool?
    var canBeIgnored: Bool?
    var email: String?
    var isEmailConfirmed: Bool?

    var lastSeenAtDate: Date? {
        // date format, example: 2022-03-23T13:37:49+00:00
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let dateString = lastSeenAt?.prefix(25) {
            return dateFormatter.date(from: String(dateString))
        }
        return nil
    }

    var joinDate: Date? {
        // date format, example: 2022-03-23T13:37:49+00:00
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let dateString = joinTime?.prefix(25) {
            return dateFormatter.date(from: String(dateString))
        }
        return nil
    }
}

struct FlarumUserRelationshipsReference {
    var userBadges: [FlarumUserBadgeReference]
    var profileAnswers: [FlarumProfileAnswerReference]
    var ignoredUsers: [FlarumUserReference]
}

final class FlarumUserReference {
    init(id: String, attributes: FlarumUserAttributes, relationships: FlarumUserRelationshipsReference? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumUserAttributes
    var relationships: FlarumUserRelationshipsReference?
}

struct FlarumUserRelationships: Codable {
    var userBadges: [FlarumUserBadge]
    var profileAnswers: [FlarumProfileAnswer]
    var ignoredUsers: [FlarumUser]

    init(_ i: FlarumUserRelationshipsReference) {
        userBadges = i.userBadges.map { .init($0) }
        profileAnswers = i.profileAnswers.map { .init($0) }
        ignoredUsers = i.ignoredUsers.map { .init($0) }
    }
}

struct FlarumUser: Codable {
    init(id: String, attributes: FlarumUserAttributes, relationships: FlarumUserRelationships? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumUserAttributes
    var relationships: FlarumUserRelationships?

    init(_ i: FlarumUserReference) {
        id = i.id
        attributes = i.attributes
        relationships = i.relationships != nil ? .init(i.relationships!) : nil
    }
}

extension FlarumUser {
    var avatarURL: URL? {
        if let url = attributes.avatarUrl {
            return URL(string: url)
        }
        return nil
    }

    func avatarPlaceholder(size: CGFloat) -> UIImage {
        let avatarView = AvatarView(frame: .init(x: 0, y: 0, width: size, height: size))
        avatarView.configuration.avatar = .init(image: nil,
                                                initials: String(attributes.displayName).filter {
                                                    $0 != "@"
                                                })
        return avatarView.image ?? UIImage()
    }

    var lastSeenAtDateDescription: String {
        if let date = attributes.lastSeenAtDate {
            return "\(date.localeDescription)在线"
        } else {
            return "未公布在线状态"
        }
    }

    var joinDateDescription: String {
        if let date = attributes.joinDate {
            return date.localeDescription
        } else {
            return "Unknown"
        }
    }

    var isOnline: Bool {
        if let lastSeenAtDate = attributes.lastSeenAtDate {
            // Less than 10 minutes
            if lastSeenAtDate.timeIntervalSinceNow > -600 {
                return true
            }
        }
        return false
    }

    var likesReceived: Int {
        attributes.likesReceived ?? 0
    }

    var commentCount: Int {
        attributes.commentCount ?? 0
    }

    var discussionCount: Int {
        attributes.discussionCount ?? 0
    }

    var isEmailConfirmed: Bool {
        attributes.isEmailConfirmed ?? false
    }
}

extension FlarumUser: Hashable {
    static func == (lhs: FlarumUser, rhs: FlarumUser) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
