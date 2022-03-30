//
//  DataParser.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/31.
//

import Foundation
import SwiftyJSON

struct IncludedData {
    var includedUsers: [User] = []
    var includedPosts: [Post] = []
    var includedTags: [Tag] = []
}

enum DataParser {
    static func parseIncludedData(json: JSON) -> IncludedData {
        var includedData = IncludedData()
        if let includedListJSON = json.array {
            for includedItemJSON in includedListJSON {
                if let incluedItemData = try? includedItemJSON.rawData() {
                    if includedItemJSON["type"].string == "tags" {
                        let relationshipsJSON = includedItemJSON["relationships"]
                        let tagJSONWithoutRelationships = includedItemJSON.removing(key: "relationships")
                        if let data = try? tagJSONWithoutRelationships.rawData(),
                           var tag = try? JSONDecoder().decode(Tag.self, from: data) {
                            if let parentId = relationshipsJSON["parent"]["data"]["id"].string {
                                tag.relationships = .init(parent: parentId)
                            }
                            includedData.includedTags.append(tag)
                        }
                    } else if includedItemJSON["type"].string == "posts",
                              let post = try? JSONDecoder().decode(Post.self, from: incluedItemData) {
                        includedData.includedPosts.append(post)
                    } else if includedItemJSON["type"].string == "users",
                              let user = try? JSONDecoder().decode(User.self, from: incluedItemData) {
                        includedData.includedUsers.append(user)
                    }
                }
            }
        }

        return includedData
    }
}
