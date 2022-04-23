//
//  FlarumUser.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/23.
//

import Foundation

struct FlarumUserAttributes: Decodable {
    var username: String
    var displayName: String
    var avatarUrl: String?
    var slug: String
}

struct FlarumUser {
    init(id: String, attributes: FlarumUserAttributes) {
        self.id = id
        self.attributes = attributes
    }

    var id: String
    var attributes: FlarumUserAttributes
}
