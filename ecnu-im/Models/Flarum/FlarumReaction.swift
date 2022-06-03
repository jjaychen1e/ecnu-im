//
//  FlarumReaction.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/23.
//

import Foundation

class FlarumReactionsPublisher: ObservableObject {
    @Published var allReactions: [FlarumReaction] = []

    static var shared = FlarumReactionsPublisher()
}

struct FlarumReactionAttributes: Codable {
    var identifier: String
    var enabled: Bool
}

struct FlarumReaction: Codable {
    init(id: String, attributes: FlarumReactionAttributes) {
        self.id = id
        self.attributes = attributes
    }

    var id: String
    var attributes: FlarumReactionAttributes
}

struct FlarumPostReactionAttributesReference {
    var user: FlarumUserReference
    var post: FlarumPostReference
    var reaction: FlarumReaction
}

class FlarumPostReactionReference {
    init(id: String, attributes: FlarumPostReactionAttributesReference) {
        self.id = id
        self.attributes = attributes
    }

    var id: String
    var attributes: FlarumPostReactionAttributesReference
}

struct FlarumPostReactionAttributesNew {
    var user: FlarumUserNew
    var post: FlarumPostNew
    var reaction: FlarumReaction

    init(_ i: FlarumPostReactionAttributesReference) {
        user = .init(i.user)
        post = .init(i.post)
        reaction = i.reaction
    }
}

struct FlarumPostReactionNew {
    init(id: String, attributes: FlarumPostReactionAttributesNew) {
        self.id = id
        self.attributes = attributes
    }

    var id: String
    var attributes: FlarumPostReactionAttributesNew

    init(_ i: FlarumPostReactionReference) {
        id = i.id
        attributes = .init(i.attributes)
    }
}
