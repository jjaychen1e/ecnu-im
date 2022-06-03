//
//  FlarumTag.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/23.
//

import Foundation
import SwiftyJSON

struct FlarumTagAttributes: Codable {
    var name: String
    var description: String
    var slug: String
    var color: String
    var icon: String
    var discussionCount: Int
    var position: Int?
    var isChild: Bool
    var isHidden: Bool
    var lastPostedAt: String
    var canStartDiscussion: Bool
    var canAddToDiscussion: Bool
}

struct FlarumTagRelationships: Codable {
    var parent: FlarumTag?
}

class Box<T> {
    var value: T
    init(value: T) {
        self.value = value
    }
}

// TODO: New - Codable
struct FlarumTagRelationshipsNew {
    private var boxedParent: Box<FlarumTagNew>?

    var parent: FlarumTagNew? {
        boxedParent?.value
    }

    init(_ i: FlarumTagRelationships) {
        boxedParent = i.parent != nil ? .init(value: .init(i.parent!)) : nil
    }

    enum CodingKeys: String, CodingKey {
        case parent
    }
}

// TODO: New - Codable
struct FlarumTagNew {
    init(id: String, attributes: FlarumTagAttributes, relationships: FlarumTagRelationshipsNew? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumTagAttributes
    var relationships: FlarumTagRelationshipsNew?

    init(_ i: FlarumTag) {
        id = i.id
        attributes = i.attributes
        relationships = i.relationships != nil ? .init(i.relationships!) : nil
    }
}

class FlarumTag: Codable {
    init(id: String, attributes: FlarumTagAttributes, relationships: FlarumTagRelationships? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumTagAttributes
    var relationships: FlarumTagRelationships?
}

extension FlarumTag: Equatable {
    static func == (lhs: FlarumTag, rhs: FlarumTag) -> Bool {
        lhs.id == rhs.id
    }
}
