//
//  FlarumBadge.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/16.
//

import Cache
import Foundation

struct FlarumBadgeAttributes: Codable {
    var name: String
    var icon: String
    var order: Int
    var description: String?
    var earnedAmount: Int
    var isVisible: Int
    var backgroundColor: String
    var iconColor: String
    var labelColor: String
    var createdAt: String
}

struct FlarumBadgeRelationships: Codable {
    var category: FlarumBadgeCategory
}

class FlarumBadge: Codable {
    init(id: String, attributes: FlarumBadgeAttributes, relationships: FlarumBadgeRelationships? = nil) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }

    var id: String
    var attributes: FlarumBadgeAttributes
    var relationships: FlarumBadgeRelationships?

    var description: String {
        attributes.description ?? "该徽章暂无描述"
    }
}

extension FlarumBadge: Hashable {
    static func == (lhs: FlarumBadge, rhs: FlarumBadge) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct FlarumBadgeStorage {
    private static let flarumBadgeDiskConfig = DiskConfig(name: "flarumBadgeDiskConfig", expiry: .never, maxSize: 10000)
    private static let flarumBadgeCategoryDiskConfig = DiskConfig(name: "flarumBadgeCategoryDiskConfig", expiry: .never, maxSize: 10000)
    private static let flarumUserBadgeDiskConfig = DiskConfig(name: "flarumUserBadgeDiskConfig", expiry: .never, maxSize: 10000)
    private static let memoryConfig = MemoryConfig(expiry: .never, countLimit: 1000, totalCostLimit: 1000)
    static let shared = FlarumBadgeStorage()

    private let flarumBadgeStorage = try? Cache.Storage<Int, FlarumBadge>(
        diskConfig: flarumBadgeDiskConfig,
        memoryConfig: memoryConfig,
        transformer: TransformerFactory.forCodable(ofType: FlarumBadge.self)
    )

    private let flarumBadgeCategoryStorage = try? Cache.Storage<Int, FlarumBadgeCategory>(
        diskConfig: flarumBadgeCategoryDiskConfig,
        memoryConfig: memoryConfig,
        transformer: TransformerFactory.forCodable(ofType: FlarumBadgeCategory.self)
    )

    private let flarumUserBadgeStorage = try? Cache.Storage<Int, FlarumUserBadge>(
        diskConfig: flarumUserBadgeDiskConfig,
        memoryConfig: memoryConfig,
        transformer: TransformerFactory.forCodable(ofType: FlarumUserBadge.self)
    )

    func store(badges: [FlarumBadge]) {
        for badge in badges {
            if let id = Int(badge.id) {
                try? flarumBadgeStorage?.setObject(badge, forKey: id, expiry: .never)
            }
        }
    }

    func badge(for id: String) -> FlarumBadge? {
        if let id = Int(id) {
            return try? flarumBadgeStorage?.object(forKey: id)
        }
        return nil
    }

    func badge(for id: Int) -> FlarumBadge? {
        try? flarumBadgeStorage?.object(forKey: id)
    }

    func store(badgeCategories: [FlarumBadgeCategory]) {
        for badgeCategory in badgeCategories {
            if let id = Int(badgeCategory.id) {
                try? flarumBadgeCategoryStorage?.setObject(badgeCategory, forKey: id, expiry: .never)
            }
        }
    }

    func badgeCategory(for id: String) -> FlarumBadgeCategory? {
        if let id = Int(id) {
            return try? flarumBadgeCategoryStorage?.object(forKey: id)
        }
        return nil
    }

    func badgeCategory(for id: Int) -> FlarumBadgeCategory? {
        try? flarumBadgeCategoryStorage?.object(forKey: id)
    }

    func store(userBadges: [FlarumUserBadge]) {
        for userBadge in userBadges {
            if let id = Int(userBadge.id) {
                try? flarumUserBadgeStorage?.setObject(userBadge, forKey: id, expiry: .never)
            }
        }
    }

    func userBadge(for id: String) -> FlarumUserBadge? {
        if let id = Int(id) {
            return try? flarumUserBadgeStorage?.object(forKey: id)
        }
        return nil
    }

    func userBadge(for id: Int) -> FlarumUserBadge? {
        try? flarumUserBadgeStorage?.object(forKey: id)
    }
}

extension FlarumBadge {
    static func initBadgeInfo() {
        Task {
            if let response = try? await flarumProvider.request(.allBadgeCategories).flarumResponse() {
                FlarumBadgeStorage.shared.store(badgeCategories: response.data.badgeCategories)
            }
        }

        Task {
            if let response = try? await flarumProvider.request(.allBadges).flarumResponse() {
                FlarumBadgeStorage.shared.store(badges: response.data.badges)
            }
        }

        if AppGlobalState.shared.tokenPrepared,
           let userId = Int(AppGlobalState.shared.userId) {
            Task {
                if let response = try? await flarumProvider.request(.user(id: userId)).flarumResponse() {
                    FlarumBadgeStorage.shared.store(userBadges: response.included.userBadges)
                }
            }
        }
    }
}
