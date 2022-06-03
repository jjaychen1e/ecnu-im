//
//  FlarumTag.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/23.
//

import Foundation
import SwiftyJSON

class Box<T> {
    var value: T
    init(value: T) {
        self.value = value
    }
}

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

struct FlarumTagRelationshipsReference: Codable {
    var parent: FlarumTagReference?
}

class FlarumTagReference: Codable {
    init(id: String, attributes: FlarumTagAttributes, relationships: FlarumTagRelationshipsReference? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumTagAttributes
    var relationships: FlarumTagRelationshipsReference?
}

// TODO: New - Codable
struct FlarumTagRelationshipsNew {
    private var boxedParent: Box<FlarumTagNew>?

    var parent: FlarumTagNew? {
        boxedParent?.value
    }

    init(_ i: FlarumTagRelationshipsReference) {
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

    init(_ i: FlarumTagReference) {
        id = i.id
        attributes = i.attributes
        relationships = i.relationships != nil ? .init(i.relationships!) : nil
    }
}

extension FlarumTagNew: Equatable {
    static func == (lhs: FlarumTagNew, rhs: FlarumTagNew) -> Bool {
        lhs.id == rhs.id
    }
}
