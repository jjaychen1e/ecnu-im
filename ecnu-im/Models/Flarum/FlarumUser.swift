//
//  FlarumUser.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/23.
//

import Foundation
import UIKit

struct FlarumUserAttributes: Decodable {
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

class FlarumUser {
    init(id: String, attributes: FlarumUserAttributes) {
        self.id = id
        self.attributes = attributes
    }

    var id: String
    var attributes: FlarumUserAttributes
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
            return date.localeDescription
        } else {
            return "Unknown"
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
}

extension FlarumUser: Equatable {
    static func == (lhs: FlarumUser, rhs: FlarumUser) -> Bool {
        lhs.id == rhs.id
    }
}
