//
//  FlarumReaction.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/23.
//

import Foundation

struct FlarumReactionAttributes: Decodable {
    var identifier: String
    var enabled: Bool
}

struct FlarumReaction: Decodable {
    init(id: String, attributes: FlarumReactionAttributes) {
        self.id = id
        self.attributes = attributes
    }

    var id: String
    var attributes: FlarumReactionAttributes
}

struct FlarumPostReactionAttributes {
    var user: FlarumUser
    var post: FlarumPost
    var reaction: FlarumReaction
}

struct FlarumPostReaction {
    init(id: String, attributes: FlarumPostReactionAttributes) {
        self.id = id
        self.attributes = attributes
    }

    var id: String
    var attributes: FlarumPostReactionAttributes
}

class FlarumReactionsPublisher: ObservableObject {
    @Published var allReactions: [FlarumReaction] = []

    static var shared = FlarumReactionsPublisher()
}
