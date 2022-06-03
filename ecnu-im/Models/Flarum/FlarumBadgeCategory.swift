//
//  FlarumBadgeCategory.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/16.
//

import Foundation

struct FlarumBadgeCategoryAttributes: Codable {
    var name: String
    var description: String?
    var order: Int
    var isEnabled: Bool
    var isTable: Bool
    var createdAt: String
}

struct FlarumBadgeCategoryRelationshipsReference {
    var badges: [FlarumBadgeReference]
}

class FlarumBadgeCategoryReference {
    init(id: String, attributes: FlarumBadgeCategoryAttributes, relationships: FlarumBadgeCategoryRelationshipsReference? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumBadgeCategoryAttributes
    var relationships: FlarumBadgeCategoryRelationshipsReference?
}

struct FlarumBadgeCategoryRelationships: Codable {
    var badges: [FlarumBadge]

    init(_ i: FlarumBadgeCategoryRelationshipsReference) {
        badges = i.badges.map { .init($0) }
    }
}

struct FlarumBadgeCategory: Codable {
    init(id: String, attributes: FlarumBadgeCategoryAttributes, relationships: FlarumBadgeCategoryRelationships? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumBadgeCategoryAttributes
    var relationships: FlarumBadgeCategoryRelationships?

    init(_ i: FlarumBadgeCategoryReference) {
        id = i.id
        attributes = i.attributes
        relationships = i.relationships != nil ? .init(i.relationships!) : nil
    }
}

extension FlarumBadgeCategory: Hashable {
    static func == (lhs: FlarumBadgeCategory, rhs: FlarumBadgeCategory) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
