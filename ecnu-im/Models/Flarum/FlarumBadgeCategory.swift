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

struct FlarumBadgeCategoryRelationshipsReference: Codable {
    var badges: [FlarumBadgeReference]
}

class FlarumBadgeCategoryReference: Codable {
    init(id: String, attributes: FlarumBadgeCategoryAttributes, relationships: FlarumBadgeCategoryRelationshipsReference? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumBadgeCategoryAttributes
    var relationships: FlarumBadgeCategoryRelationshipsReference?
}

struct FlarumBadgeCategoryRelationshipsNew: Codable {
    var badges: [FlarumBadgeNew]

    init(_ i: FlarumBadgeCategoryRelationshipsReference) {
        badges = i.badges.map { .init($0) }
    }
}

struct FlarumBadgeCategoryNew: Codable {
    init(id: String, attributes: FlarumBadgeCategoryAttributes, relationships: FlarumBadgeCategoryRelationshipsNew? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumBadgeCategoryAttributes
    var relationships: FlarumBadgeCategoryRelationshipsNew?

    init(_ i: FlarumBadgeCategoryReference) {
        id = i.id
        attributes = i.attributes
        relationships = i.relationships != nil ? .init(i.relationships!) : nil
    }
}

extension FlarumBadgeCategoryNew: Hashable {
    static func == (lhs: FlarumBadgeCategoryNew, rhs: FlarumBadgeCategoryNew) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
