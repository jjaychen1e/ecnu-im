//
//  PostUserStorage.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/17.
//

import Cache
import Foundation

struct DiscussionUserStorage {
    private static let diskConfig = DiskConfig(name: "DiscussionUserStorage", expiry: .never, maxSize: 10000)
    private static let memoryConfig = MemoryConfig(expiry: .never, countLimit: 1000, totalCostLimit: 1000)
    static let shared = DiscussionUserStorage()

    private let storage = try? Cache.Storage<String, [FlarumUser]>(
        diskConfig: diskConfig,
        memoryConfig: memoryConfig,
        transformer: TransformerFactory.forCodable(ofType: [FlarumUser].self)
    )

    func store(discussionUsers: [FlarumUser], id: String) {
        try? storage?.setObject(discussionUsers, forKey: id, expiry: .never)
    }

    func discussionUsers(for id: String) -> [FlarumUser]? {
        try? storage?.object(forKey: id)
    }
}
