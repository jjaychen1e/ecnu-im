//
//  FlarumResponse.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/23.
//

import Foundation
import SwiftUI
import SwiftyJSON

struct FlarumResponse {
    struct FlarumResponseData {
        var allData: [FlarumData] = []
        var discussions: [FlarumDiscussion] = []
        var posts: [FlarumPost] = []
        var users: [FlarumUser] = []
        var tags: [FlarumTag] = []
        var postReactions: [FlarumPostReaction] = []
    }

    var links: FlarumLinks?
    var data: FlarumResponseData

    init(json: JSON) {
        links = json["links"].decode(FlarumLinks.self)
        data = .init()

        let includedFirst = parseData(json: json["included"])
        // Not all relationships are included in data section!
        // For example, when you request for discussions list, in the data section,
        //  a discussion only has relationship info between itself and tags, but no
        //  relationship info between tags. That means in the data section, it only
        //  contains first level relationships.
        // We can easily tackle this problem with one more time traverse.
        let included = parseData(json: json["included"], withRelationship: true, includedData: includedFirst)
        data = parseData(json: json["data"], withRelationship: true, includedData: included)
    }

    private func parseData(json: JSON, withRelationship: Bool = false, includedData: FlarumResponseData? = nil) -> FlarumResponseData {
        var responseData = FlarumResponseData()
        if let dataJSONArray = json.array {
            for dataJSON in dataJSONArray {
                // Different type's attributes
                if let dataType = FlarumDataType(rawValue: dataJSON["type"].string ?? "") {
                    switch dataType {
                    case .discussion:
                        if let id = dataJSON["id"].string {
                            let discussion = FlarumDiscussion(id: id)
                            discussion.attributes = dataJSON["attributes"].decode(FlarumDiscussionAttributes.self)
                            if withRelationship, let includedData = includedData {
                                var relationships = FlarumDiscussionRelationships()
                                if let dic = dataJSON["relationships"].dictionary {
                                    for relationship in FlarumDiscussionRelationships.Relationship.allCases {
                                        switch relationship {
                                        case .user:
                                            if let userId = dic["user"]?["data"]["id"].string {
                                                relationships.user = includedData.users.first(where: { $0.id == userId })
                                            }
                                        case .lastPostedUser:
                                            if let userId = dic["lastPostedUser"]?["data"]["id"].string {
                                                relationships.lastPostedUser = includedData.users.first(where: { $0.id == userId })
                                            }
                                        case .firstPost:
                                            if let postId = dic["firstPost"]?["data"]["id"].string {
                                                relationships.firstPost = includedData.posts.first(where: { $0.id == postId })
                                            }
                                        case .lastPost:
                                            if let postId = dic["lastPost"]?["data"]["id"].string {
                                                relationships.lastPost = includedData.posts.first(where: { $0.id == postId })
                                            }
                                        case .tags:
                                            if let tagIds = dic["tags"]?["data"].array?.compactMap({ $0["id"].string }) {
                                                relationships.tags = includedData.tags.filter { tagIds.contains($0.id) }
                                            }
                                        }
                                    }
                                }
                                discussion.relationships = relationships
                            }
                            responseData.allData.append(.discussion(discussion))
                            responseData.discussions.append(discussion)
                        }
                    case .post:
                        if let id = dataJSON["id"].string {
                            let post = FlarumPost(id: id)
                            var attributes = dataJSON["attributes"]
                            if attributes["content"].exists() {
                                if attributes["contentType"] == "comment" {
                                    var json = JSON()
                                    json["_0"] = attributes["content"]
                                    attributes["content"] = JSON(dictionaryLiteral: ("comment", json))
                                } else if attributes["contentType"] == "discussionTagged" {
                                    var json = JSON()
                                    json["_0"] = attributes["content"]
                                    attributes["content"] = JSON(dictionaryLiteral: ("discussionTagged", json))
                                } else if attributes["contentType"] == "discussionRenamed" {
                                    var json = JSON()
                                    json["_0"] = attributes["content"]
                                    attributes["content"] = JSON(dictionaryLiteral: ("discussionRenamed", json))
                                } else if attributes["contentType"] == "discussionLocked" {
                                    var json = JSON()
                                    json["_0"] = attributes["content"]
                                    attributes["content"] = JSON(dictionaryLiteral: ("discussionLocked", json))
                                } else {
                                    // discussionSuperStickied, discussionMerged
                                    attributes = attributes.removing(key: "content")
                                    attributes = attributes.removing(key: "contentType")
                                }
                            }
                            post.attributes = attributes.decode(FlarumPostAttributes.self)
                            if withRelationship, let includedData = includedData {
                                var relationships = FlarumPostRelationships()
                                for relationship in FlarumPostRelationships.Relationship.allCases {
                                    switch relationship {
                                    case .discussion:
                                        if let discussionId = dataJSON["relationships"]["discussion"]["data"]["id"].string {
                                            relationships.discussion = includedData.discussions.first(where: { $0.id == discussionId })
                                        }
                                    case .user:
                                        if let userId = dataJSON["relationships"]["user"]["data"]["id"].string {
                                            relationships.user = includedData.users.first(where: { $0.id == userId })
                                        }
                                    case .reactions:
                                        if let reactionIds = dataJSON["relationships"]["reactions"]["data"].array?.compactMap({ $0["post_reactions"].string }) {
                                            relationships.reactions = includedData.postReactions.filter { reactionIds.contains($0.id) }
                                        }
                                    case .likes:
                                        if let likeIds = dataJSON["relationships"]["likes"]["data"].array?.compactMap({ $0["id"].string }) {
                                            relationships.likes = includedData.users.filter { likeIds.contains($0.id) }
                                        }
                                    case .mentionedBy:
                                        if let mentionedByIds = dataJSON["relationships"]["mentionedBy"]["data"].array?.compactMap({ $0["id"].string }) {
                                            relationships.mentionedBy = includedData.users.filter { mentionedByIds.contains($0.id) }
                                        }
                                    }
                                }
                                post.relationships = relationships
                            }
                            responseData.allData.append(.post(post))
                            responseData.posts.append(post)
                        }
                    case .user:
                        if let id = dataJSON["id"].string {
                            if let attributes = dataJSON["attributes"].decode(FlarumUserAttributes.self) {
                                let user = FlarumUser(id: id, attributes: attributes)
                                responseData.allData.append(.user(user))
                                responseData.users.append(user)
                            }
                        }
                    case .tag:
                        if let id = dataJSON["id"].string {
                            if let tagAttributes = dataJSON["attributes"].decode(FlarumTagAttributes.self) {
                                let tag = FlarumTag(id: id, attributes: tagAttributes)
                                if withRelationship, let includedData = includedData {
                                    var relationships = FlarumTagRelationships()
                                    if let parentId = dataJSON["relationships"]["parent"]["data"]["id"].string {
                                        if let parentTag = includedData.tags.first(where: { $0.id == parentId }) {
                                            relationships.parent = parentTag
                                        }
                                        tag.relationships = relationships
                                    }
                                }
                                responseData.allData.append(.tag(tag))
                                responseData.tags.append(tag)
                            }
                        }
                    case .postReaction:
                        if let id = dataJSON["id"].string {
                            if let userId = dataJSON["attributes"]["userId"].string,
                               let postId = dataJSON["attributes"]["postId"].string,
                               let reactionId = dataJSON["attributes"]["reactionId"].string,
                               let user = includedData?.users.first(where: { userId == $0.id }),
                               let post = includedData?.posts.first(where: { postId == $0.id }),
                               let reaction = FlarumReactionsPublisher.shared.allReactions.first(where: { reactionId == $0.id }) {
                                let postReaction = FlarumPostReaction(id: id, attributes: .init(user: user, post: post, reaction: reaction))
                                responseData.allData.append(.postReaction(postReaction))
                                responseData.postReactions.append(postReaction)
                            }
                        }
                    }
                }
            }
        }

        return responseData
    }
}

enum FlarumDataType: String, RawRepresentable {
    case discussion = "discussions"
    case post = "posts"
    case user = "users"
    case tag = "tags"
    case postReaction = "post_reactions"
}

enum FlarumData {
    case discussion(FlarumDiscussion)
    case post(FlarumPost)
    case user(FlarumUser)
    case tag(FlarumTag)
    case postReaction(FlarumPostReaction)
}
