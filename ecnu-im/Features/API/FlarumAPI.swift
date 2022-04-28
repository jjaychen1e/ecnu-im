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
    case allDiscussions(includes: Set<DiscussionIncludeOption> = DiscussionIncludeOption.homeDiscussionIncludeOptionSet,
                        pageOffset: Int = 0,
                        pageItemLimit: Int = 20)
    case posts(discussionID: Int, offset: Int, limit: Int)
    case postsById(id: Int)
    case register(email: String, username: String, nickname: String, password: String, recaptcha: String)
    case newPost(discussionID: String, content: String)
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
        case .allDiscussions:
            return "/api/discussions"
        case .posts:
            return "/api/posts"
        case .postsById:
            return "/api/posts"
        case .register:
            return "/register"
        case .newPost:
            return "api/posts"
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
        case .allDiscussions:
            return .get
        case .posts:
            return .get
        case .postsById:
            return .get
        case .register:
            return .post
        case .newPost:
            return .post
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
        case let .allDiscussions(includes, pageOffset, pageLimit):
            return .requestParameters(parameters: [
                "include": includes.map { $0.rawValue }.joined(separator: ","),
                "page[offset]": pageOffset,
                "page[limit]": pageLimit,
            ], encoding: URLEncoding.default)
        case let .posts(discussionID, offset, limit):
            return .requestParameters(parameters: [
                "filter[discussion]": discussionID,
                "page[offset]": max(0, offset),
                "page[limit]": limit,
            ], encoding: URLEncoding.default)
        case let .postsById(id: id):
            return .requestParameters(parameters: [
                "filter[id]": "\(id)"
            ], encoding: URLEncoding.default)
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
        }
    }

    var headers: [String: String]? {
        get async {
            let basicHeader = [
                "Accept-Language": "zh-CN,zh;",
            ]
            switch self {
            case .register, .newPost:
                let regex = Regex("\"csrfToken\":\"(.*?)\"")
                if let homeResult = try? await flarumProvider.request(.home),
                   let homeContentStr = try? homeResult.mapString(),
                   let csrfToken = regex.firstMatch(in: homeContentStr)?.captures[0] {
                    return basicHeader.merging(["X-CSRF-Token": csrfToken]) { _, new in new }
                }
                fallthrough
            default:
                return basicHeader
            }
        }
    }
}
