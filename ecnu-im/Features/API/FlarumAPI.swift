//
//  FlarumAPI.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/26.
//

import Foundation

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
    case allDisscussions(includes: Set<DiscussionIncludeOption> = DiscussionIncludeOption.homeDiscussionIncludeOptionSet,
                         pageOffset: Int = 0,
                         pageItemLimit: Int = 20)
    case posts(discussionID: Int, offset: Int, limit: Int)
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
        case .allDisscussions:
            return "/api/discussions"
        case .posts:
            return "/api/posts"
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
        case .allDisscussions:
            return .get
        case .posts:
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
        case let .allDisscussions(includes, pageOffset, pageLimit):
            return .requestParameters(parameters: [
                "include": includes.map { $0.rawValue }.joined(separator: ","),
                "page[offset]": pageOffset,
                "page[limit]": pageLimit,
            ], encoding: URLEncoding.default)
        case let .posts(discussionID, offset, limit):
            return .requestParameters(parameters: [
                "filter[discussion]": discussionID,
                "page[offset]": max(0, offset),
                "page[limit]": limit
            ], encoding: URLEncoding.default)
        }
    }

    var headers: [String: String]? {
        nil
    }
}
