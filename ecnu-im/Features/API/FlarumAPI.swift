//
//  FlarumAPI.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/26.
//

import Foundation
import Regex

let flarumProvider = APIProvider<Flarum>()
let flarumBaseURL = "https://ecnu.im"

enum DiscussionIncludeOption: String, RawRepresentable {
    case user
    case lastPostedUser
    case firstPost
    case lastPost
    case tags
    case tagsParent = "tags.parent"
    case recipientUsers
    case recipientGroups

    static let homeDiscussionIncludeOptionSet: Set<Self> = {
        [.user, .lastPostedUser, .firstPost, .lastPost, .tags, .tagsParent, .recipientUsers, .recipientGroups]
    }()

    static let profileDiscussionIncludeOptionSet: Set<Self> = {
        [.user, .lastPostedUser, .lastPost, .tags, .tagsParent]
    }()
}

enum PostIncludeOption: String, RawRepresentable {
    case user
    case likes
    case mentionedBy
    case mentionedBy_User = "mentionedBy.user"
}

enum DiscussionSortOption: String, RawRepresentable {
    case newest = "-createdAt"
    case oldest = "createdAt"
    case latest = "-lastPostedAt"
    case mostComment = "-commentCount"
}

enum Flarum {
    case home
    case token(username: String, password: String)
    case allTags
    case discussionInfo(discussionID: Int)
    case allDiscussions(includes: Set<DiscussionIncludeOption> = DiscussionIncludeOption.homeDiscussionIncludeOptionSet,
                        pageOffset: Int = 0,
                        pageItemLimit: Int = 20)
    case discussionByUserAccount(includes: Set<DiscussionIncludeOption> = DiscussionIncludeOption.profileDiscussionIncludeOptionSet,
                                 account: String, offset: Int, limit: Int, sort: DiscussionSortOption = .newest)
    case hidePost(id: Int, isHidden: Bool)
    case deletePost(id: Int)
    case posts(discussionID: Int, offset: Int, limit: Int)
    case postsNearNumber(discussionID: Int, nearNumber: Int, limit: Int)
    case postsById(id: Int, includes: Set<PostIncludeOption> = [.user])
    case postsByIds(ids: [Int], includes: Set<PostIncludeOption> = [.user])
    case postsByUserAccount(account: String, offset: Int, limit: Int, sort: DiscussionSortOption = .newest)
    case postLikeAction(id: Int, like: Bool)
    case register(email: String, username: String, nickname: String, password: String, recaptcha: String)
    case newPost(discussionID: String, content: String)
    case editPost(postID: Int, content: String)
    case notification(offset: Int, limit: Int)
    case lastSeenUsers(limit: Int)
    case user(id: Int)
    case ignoreUser(id: Int, ignored: Bool)
    case allBadgeCategories
    case allBadges
}

extension Flarum: TargetType {
    var baseURL: URL {
        URL(string: flarumBaseURL)!
    }

    var path: String {
        switch self {
        case .home:
            return "/"
        case .token:
            return "/api/token"
        case .allTags:
            return "/api/tags"
        case let .discussionInfo(discussionID):
            return "/api/discussions/\(discussionID)"
        case .allDiscussions:
            return "/api/discussions"
        case .discussionByUserAccount:
            return "/api/discussions"
        case let .hidePost(id, _):
            return "/api/posts/\(id)"
        case let .deletePost(id):
            return "/api/posts/\(id)"
        case .posts:
            return "/api/posts"
        case .postsNearNumber:
            return "/api/posts"
        case .postsById:
            return "/api/posts"
        case .postsByIds:
            return "/api/posts"
        case .postsByUserAccount:
            return "/api/posts"
        case let .postLikeAction(id, _):
            return "/api/posts/\(id)"
        case .register:
            return "/register"
        case .newPost:
            return "api/posts"
        case let .editPost(postID, _):
            return "api/posts/\(postID)"
        case .notification:
            return "api/notifications"
        case .lastSeenUsers:
            return "api/users"
        case let .user(id):
            return "api/users/\(id)"
        case let .ignoreUser(id, _):
            return "api/users/\(id)"

        case .allBadgeCategories:
            return "api/badge_categories"
        case .allBadges:
            return "api/badges"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .home:
            return .get
        case .token:
            return .post
        case .allTags:
            return .get
        case .discussionInfo:
            return .get
        case .allDiscussions:
            return .get
        case .discussionByUserAccount:
            return .get
        case .hidePost:
            return .patch
        case .deletePost:
            return .delete
        case .posts:
            return .get
        case .postsNearNumber:
            return .get
        case .postsById:
            return .get
        case .postsByIds:
            return .get
        case .postsByUserAccount:
            return .get
        case .postLikeAction:
            return .patch
        case .register:
            return .post
        case .newPost:
            return .post
        case .editPost:
            return .patch
        case .notification:
            return .get
        case .lastSeenUsers:
            return .get
        case .user:
            return .get
        case .ignoreUser:
            return .patch
        case .allBadgeCategories:
            return .get
        case .allBadges:
            return .get
        }
    }

    var task: RequestTask {
        switch self {
        case .home:
            return .requestPlain
        case let .token(username, password):
            return .requestParameters(parameters: [
                "identification": username,
                "password": password,
                "remember": true,
            ], encoding: JSONEncoding.default)
        case .allTags:
            return .requestPlain
        case .discussionInfo:
            return .requestParameters(parameters: [
                "page[offset]": 0,
                "page[limit]": 1,
            ], encoding: URLEncoding.default)
        case let .allDiscussions(includes, pageOffset, pageLimit):
            return .requestParameters(parameters: [
                "include": includes.map { $0.rawValue }.joined(separator: ","),
                "page[offset]": pageOffset,
                "page[limit]": pageLimit,
            ], encoding: URLEncoding.default)
        case let .discussionByUserAccount(includes, account, offset, limit, sort):
            return .requestParameters(parameters: [
                "include": includes.map { $0.rawValue }.joined(separator: ","),
                "filter[author]": account,
                "page[offset]": offset,
                "page[limit]": limit,
                "sort": sort.rawValue,
            ], encoding: URLEncoding.default)
        case let .hidePost(id, isHidden):
            return .requestParameters(parameters: [
                "data": [
                    "type": "posts",
                    "attributes": [
                        "isHidden": isHidden,
                    ],
                    "id": id,
                ],
            ], encoding: JSONEncoding.default)
        case .deletePost:
            return .requestPlain
        case let .posts(discussionID, offset, limit):
            return .requestParameters(parameters: [
                "filter[discussion]": discussionID,
                "page[offset]": max(0, offset),
                "page[limit]": limit,
            ], encoding: URLEncoding.default)
        case let .postsNearNumber(discussionID, nearNumber, limit):
            return .requestParameters(parameters: [
                "filter[discussion]": discussionID,
                "page[near]": max(0, nearNumber),
                "page[limit]": limit,
            ], encoding: URLEncoding.default)
        case let .postsById(id, includes):
            return .requestParameters(parameters: [
                "filter[id]": "\(id)",
                "include": includes.map { $0.rawValue }.joined(separator: ","),
            ], encoding: URLEncoding.default)
        case let .postsByIds(ids, includes):
            return .requestParameters(parameters: [
                "filter[id]": ids.map { String($0) }.joined(separator: ","),
                "include": includes.map { $0.rawValue }.joined(separator: ","),
            ], encoding: URLEncoding.default)
        case let .postsByUserAccount(account, offset, limit, sort):
            return .requestParameters(parameters: [
                "filter[author]": account,
                "page[offset]": offset,
                "page[limit]": limit,
                "sort": sort.rawValue,
            ], encoding: URLEncoding.default)
        case let .postLikeAction(id, like):
            return .requestParameters(parameters: [
                "data": [
                    "type": "posts",
                    "attributes": [
                        "isLiked": like,
                    ],
                    "id": id,
                ],
            ], encoding: JSONEncoding.default)
        case let .register(email, username, nickname, password, recaptcha):
            return .requestParameters(parameters: [
                "username": username,
                "email": email,
                "password": password,
                "fof_terms_policy_1": true,
                "g-recaptcha-response": recaptcha,
                "nickname": nickname,
            ], encoding: JSONEncoding.default)
        case let .newPost(discussionID, content):
            return .requestParameters(parameters: [
                "data": [
                    "type": "posts",
                    "attributes": [
                        "content": content,
                    ],
                    "relationships": [
                        "discussion": [
                            "data": [
                                "type": "discussions",
                                "id": discussionID,
                            ],
                        ],
                    ],
                ],
            ], encoding: JSONEncoding.default)
        case let .editPost(postID, content):
            return .requestParameters(parameters: [
                "data": [
                    "type": "posts",
                    "id": "\(postID)",
                    "attributes": [
                        "content": content,
                    ],
                ],
            ], encoding: JSONEncoding.default)

        case let .notification(offset, limit):
            return .requestParameters(parameters: [
                "page[offset]": max(0, offset),
                "page[limit]": limit,
            ], encoding: URLEncoding.default)
        case let .lastSeenUsers(limit):
            return .requestParameters(parameters: [
                "sort": "-lastSeenAt",
                "page[offset]": 0,
                "page[limit]": limit,
            ], encoding: URLEncoding.default)
        case .user:
            return .requestPlain
        case let .ignoreUser(id, ignored):
            return .requestParameters(parameters: [
                "data": [
                    "type": "users",
                    "id": "\(id)",
                    "attributes": [
                        "ignored": ignored,
                    ],
                ],
            ], encoding: JSONEncoding.default)
        case .allBadgeCategories:
            return .requestPlain
        case .allBadges:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        get async {
            let basicHeader = [
                "Accept-Language": "zh-CN,zh;",
            ]
            let whitelist: [HTTPMethod] = [.post, .delete, .patch]
            if whitelist.contains(method) {
                let regex = Regex("\"csrfToken\":\"(.*?)\"")
                if let homeResult = try? await flarumProvider.request(.home),
                   let homeContentStr = try? homeResult.mapString(),
                   let csrfToken = regex.firstMatch(in: homeContentStr)?.captures[0] {
                    return basicHeader.merging(["X-CSRF-Token": csrfToken]) { _, new in new }
                }
            }
            return basicHeader
        }
    }
}
