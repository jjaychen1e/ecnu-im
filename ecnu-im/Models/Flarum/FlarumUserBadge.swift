//
//  FlarumUserBadge.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/16.
//

import Foundation

struct FlarumUserBadgeAttributes: Codable {
    var isPrimary: Int
    var description: String?
    var assignedAt: String

    var assignedAtDate: Date? {
        // date format, example: 2022-03-23T13:37:49+00:00
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let dateString = assignedAt.prefix(25)
        return dateFormatter.date(from: String(dateString))
    }
}

struct FlarumUserBadgeRelationshipsReference {
    var badge: FlarumBadgeReference
}

class FlarumUserBadgeReference {
    init(id: String, attributes: FlarumUserBadgeAttributes, relationships: FlarumUserBadgeRelationshipsReference? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumUserBadgeAttributes
    var relationships: FlarumUserBadgeRelationshipsReference?
}

struct FlarumUserBadgeRelationships: Codable {
    var badge: FlarumBadge

    init(_ i: FlarumUserBadgeRelationshipsReference) {
        badge = .init(i.badge)
    }
}

struct FlarumUserBadge: Codable {
    init(id: String, attributes: FlarumUserBadgeAttributes, relationships: FlarumUserBadgeRelationships? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumUserBadgeAttributes
    var relationships: FlarumUserBadgeRelationships?

    var assignedAtDateDescription: String {
        if let date = attributes.assignedAtDate {
            return date.localeDescription
        } else {
            return "Unknown"
        }
    }

    init(_ i: FlarumUserBadgeReference) {
        id = i.id
        attributes = i.attributes
        relationships = i.relationships != nil ? .init(i.relationships!) : nil
    }
}

extension FlarumUserBadge: Hashable {
    static func == (lhs: FlarumUserBadge, rhs: FlarumUserBadge) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
