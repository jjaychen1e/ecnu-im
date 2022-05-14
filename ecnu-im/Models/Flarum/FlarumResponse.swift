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
        var notifications: [FlarumNotification] = []
    }

    var links: FlarumLinks?
    var data: FlarumResponseData
    var included: FlarumResponseData

    init(json: JSON) {
        links = json["links"].decode(FlarumLinks.self)
        data = .init()
        included = .init()

        let includedFirst = parseData(json: json["included"])
        // Not all relationships are included in data section!
        // For example, when you request for discussions list, in the data section,
        //  a discussion only has relationship info between itself and tags, but no
        //  relationship info between tags. That means in the data section, it only
        //  contains first level relationships.
        // We can easily tackle this problem with one more time traverse.
        // TODO: It seems 2 round traversing is insufficient? We should use reference
        //  type for all root types.
        let included = parseData(json: json["included"], withRelationship: true, includedData: includedFirst)
        self.included = included
        data = parseData(json: json["data"], withRelationship: true, includedData: included)
    }

    private func parseData(json: JSON, withRelationship: Bool = false, includedData: FlarumResponseData? = nil) -> FlarumResponseData {
        var responseData = FlarumResponseData()
        var jsonArray: [JSON] = []
        if let dataJSONArray = json.array {
            jsonArray.append(contentsOf: dataJSONArray)
        } else {
            jsonArray.append(json)
        }

        for dataJSON in jsonArray {
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
                            if let contentType = FlarumPostAttributes.FlarumPostContentType(rawValue: attributes["contentType"].string ?? "") {
                                switch contentType {
                                case .comment:
                                    var json = JSON()
                                    json["_0"] = attributes["content"]
                                    attributes["content"] = JSON(dictionaryLiteral: ("comment", json))
                                case .discussionRenamed:
                                    var json = JSON()
                                    json["_0"] = attributes["content"]
                                    attributes["content"] = JSON(dictionaryLiteral: ("discussionRenamed", json))
                                case .discussionTagged:
                                    var json = JSON()
                                    json["_0"] = attributes["content"]
                                    attributes["content"] = JSON(dictionaryLiteral: ("discussionTagged", json))
                                case .discussionLocked:
                                    var json = JSON()
                                    json["_0"] = attributes["content"]["locked"]
                                    attributes["content"] = JSON(dictionaryLiteral: ("discussionLocked", json))
                                }
                            } else {
                                #if DEBUG
                                    let whitelist = ["discussionSuperStickied", "discussionMerged", "recipientsModified"]
                                    if let contentType = attributes["contentType"].string,
                                       !whitelist.contains(contentType) {
                                        fatalError("\(contentType) is not in the whitelist.")
                                    }
                                #endif
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
                                        relationships.mentionedBy = includedData.posts.filter { mentionedByIds.contains($0.id) }
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
                case .notification:
                    if let id = dataJSON["id"].string {
                        var attributes = dataJSON["attributes"]
                        if attributes["content"].exists() {
                            if let contentType = FlarumNotificationAttributes.FlarumNotificationContentType(rawValue: attributes["contentType"].string ?? "") {
                                switch contentType {
                                case .postLiked:
                                    attributes["content"] = JSON([
                                        "postLiked": [:],
                                    ])
                                case .postMentioned:
                                    attributes["content"] = JSON([
                                        "postMentioned": attributes["content"],
                                    ])
                                case .postReacted:
                                    if let reactionString = attributes["content"].string {
                                        var json = JSON(parseJSON: reactionString)

                                        if json["enabled"] == 1 {
                                            json["enabled"] = true
                                        } else if json["enabled"] == 0 {
                                            json["enabled"] = false
                                        }

                                        if let id = json["id"].int,
                                           let reactionAtt = json.decode(FlarumReactionAttributes.self) {
                                            let reaction = FlarumReaction(id: "\(id)", attributes: reactionAtt)
                                            if let data = try? JSONEncoder().encode(FlarumNotificationAttributes.FlarumNotificationContent.postReacted(reaction: reaction)) {
                                                let json = JSON(data)
                                                attributes["content"] = json
                                            }
                                        }
                                    }
                                case .privateDiscussionReplied:
                                    attributes["content"] = JSON([
                                        "privateDiscussionReplied": attributes["content"],
                                    ])
                                case .privateDiscussionCreated:
                                    attributes["content"] = JSON([
                                        "privateDiscussionCreated": [:],
                                    ])
                                }
                            } else {
                                #if DEBUG
                                    let whitelist: [String] = []
                                    if let contentType = attributes["contentType"].string,
                                       !whitelist.contains(contentType) {
                                        fatalError("\(contentType) is not in the whitelist.")
                                    }
                                #endif
                                attributes = attributes.removing(key: "content")
                                attributes = attributes.removing(key: "contentType")
                            }
                        }
                        if let attributes = attributes.decode(FlarumNotificationAttributes.self) {
                            let notification = FlarumNotification(id: id, attributes: attributes)
                            if withRelationship, let includedData = includedData {
                                if let userId = dataJSON["relationships"]["fromUser"]["data"]["id"].string,
                                   let user = includedData.users.first(where: { $0.id == userId }) {
                                    if let subjectType = FlarumNotificationRelationships.SubjectType(rawValue:
                                        dataJSON["relationships"]["subject"]["data"]["type"].string ?? ""
                                    ) {
                                        switch subjectType {
                                        case .post:
                                            if let postId = dataJSON["relationships"]["subject"]["data"]["id"].string,
                                               let post = includedData.posts.first(where: { $0.id == postId }) {
                                                let relationships = FlarumNotificationRelationships(fromUser: user, subject: .post(post: post))
                                                notification.relationships = relationships
                                            }
                                        case .discussion:
                                            if let discussionId = dataJSON["relationships"]["subject"]["data"]["id"].string,
                                               let discussion = includedData.discussions.first(where: { $0.id == discussionId }) {
                                                let relationships = FlarumNotificationRelationships(fromUser: user, subject: .discussion(discussion: discussion))
                                                notification.relationships = relationships
                                            }
                                        }
                                    } else {
                                        #if DEBUG
                                            let whitelist: [String] = []
                                            if let subjectType = dataJSON["relationships"]["subject"]["data"]["type"].string,
                                               !whitelist.contains(subjectType) {
                                                fatalError("\(subjectType) is not in the whitelist.")
                                            }
                                        #endif
                                    }
                                }
                            }
                            responseData.allData.append(.notification(notification))
                            responseData.notifications.append(notification)
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
    case notification = "notifications"
}

enum FlarumData {
    case discussion(FlarumDiscussion)
    case post(FlarumPost)
    case user(FlarumUser)
    case tag(FlarumTag)
    case postReaction(FlarumPostReaction)
    case notification(FlarumNotification)
}

extension Response {
    func flarumResponse() -> FlarumResponse {
        let json = JSON(data)
        return FlarumResponse(json: json)
    }
}
