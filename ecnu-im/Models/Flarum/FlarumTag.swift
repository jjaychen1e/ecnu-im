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

extension FlarumTag {
    static let UserDefaultsKeyAllTags = "AllTags"

    static func initTagInfo(viewModel: TagsViewModel) {
        Task {
            let tags = await fetchTagsInfo()
            let tagsViewModel: [TagViewModel] = tags.map { tag in
                TagViewModel(tag: tag)
            }
            DispatchQueue.main.async {
                viewModel.tags = tagsViewModel
            }
            UserDefaults.standard.setEncodable(tags, forKey: FlarumTag.UserDefaultsKeyAllTags)
        }

        if let allTags = UserDefaults.standard.object(forKey: FlarumTag.UserDefaultsKeyAllTags, type: [FlarumTag].self) {
            let tagsViewModel: [TagViewModel] = allTags.map { tag in
                TagViewModel(tag: tag)
            }
            DispatchQueue.main.async {
                viewModel.tags = tagsViewModel
            }
        }
    }

    private static func fetchTagsInfo() async -> [FlarumTag] {
        if let response = try? await flarumProvider.request(.allTags) {
            let data = response.data
            let json = JSON(data)
            return FlarumResponse(json: json).data.tags
        }
        return []
    }
}
