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
