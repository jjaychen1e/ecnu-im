//
//  User.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/26.
//

import Foundation

struct UserAttribute: Decodable {
    var username: String?
    var displayName: String?
    var avatarUrl: String?
    var slug: String?
}

struct User: Decodable {
    var id: String
    var attributes: UserAttribute?
}
