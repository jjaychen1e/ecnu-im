//
//  Tag.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/26.
//

import FontAwesome
import Foundation
import SwiftUI
import SwiftyJSON
import UIColorHexSwift

struct Tag: Codable {
    var id: String
    var attributes: TagAttribute?
    var relationships: TagRelationship?
}

extension Tag: Equatable {
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }
}

struct TagRelationship: Codable {
    var parent: String?
}

struct TagAttribute: Codable {
    var name: String?
    var description: String?
    var slug: String?
    var color: String?
    var icon: String?
    var discussionCount: Int?
    var position: Int?
    var isChild: Bool?
    var isHidden: Bool?
    var lastPostedAt: String?
    var canStartDiscussion: Bool?
    var canAddToDiscussion: Bool?

    var lastPostedDate: Date? {
        // date format, exmaple: 2022-03-23T13:37:49+00:00
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let dateString = lastPostedAt?.prefix(25) {
            return dateFormatter.date(from: String(dateString))
        }
        return nil
    }
}

extension Tag {
    static let UserDefaultsKeyAllTags = "AllTags"
    static let UserDefaultsKeyAllParentTags = "AllParentTags"

    static func initTagInfo(viewModel: TagsViewModel) -> (allTags: [Tag], allParentTags: [Tag]) {
        Task {
            let result = await fetchTagsInfo()
            let allTags = result.allTags
            let allParentTags = result.allParentTags
            let tagsViewModel: [TagViewModel] = allTags.map { tag in
                if let parent = tag.relationships?.parent {
                    let parentTag = allParentTags.first { item in item.id == parent }
                    return TagViewModel(tag: tag, parentTag: parentTag)
                }
                return TagViewModel(tag: tag)
            }
            let parentTagsViewModel = allParentTags.map { TagViewModel(tag: $0) }
            DispatchQueue.main.async {
                viewModel.allTags = tagsViewModel
                viewModel.allParentTags = parentTagsViewModel
            }
            UserDefaults.standard.setEncodable(allTags, forKey: Tag.UserDefaultsKeyAllTags)
            UserDefaults.standard.setEncodable(allParentTags, forKey: Tag.UserDefaultsKeyAllParentTags)
        }

        if let allTags = UserDefaults.standard.object(forKey: Tag.UserDefaultsKeyAllTags, type: [Tag].self),
           let allParentTags = UserDefaults.standard.object(forKey: Tag.UserDefaultsKeyAllParentTags, type: [Tag].self) {
            let tagsViewModel: [TagViewModel] = allTags.map { tag in
                if let parent = tag.relationships?.parent {
                    let parentTag = allParentTags.first { item in item.id == parent }
                    return TagViewModel(tag: tag, parentTag: parentTag)
                }
                return TagViewModel(tag: tag)
            }
            let parentTagsViewModel = allParentTags.map { TagViewModel(tag: $0) }
            DispatchQueue.main.async {
                viewModel.allTags = tagsViewModel
                viewModel.allParentTags = parentTagsViewModel
            }
            return (allTags, allParentTags)
        }

        return ([], [])
    }

    private static func fetchTagsInfo() async -> (allTags: [Tag], allParentTags: [Tag]) {
        var allTags: [Tag] = []
        var allParentTags: [Tag] = []
        if let response = try? await flarumProvider.request(.allTags) {
            let data = response.data
            let json = JSON(data)
            if let allTagsJSONArray = json["data"].array,
               let allParentTagsJSONArray = json["included"].array {
                for tagJSON in allTagsJSONArray {
                    let relationshipsJSON = tagJSON["relationships"]
                    let tagJSONWithoutRelationships = tagJSON.removing(key: "relationships")
                    if let data = try? tagJSONWithoutRelationships.rawData() {
                        var tag = try! JSONDecoder().decode(Tag.self, from: data)
                        if let parentId = relationshipsJSON["parent"]["data"]["id"].string {
                            tag.relationships = .init(parent: parentId)
                        }
                        allTags.append(tag)
                    }
                }

                for tagJSON in allParentTagsJSONArray {
                    var tagJSONWithoutRelationships = tagJSON
                    tagJSONWithoutRelationships["relationships"] = [:]
                    if let data = try? tagJSONWithoutRelationships.rawData(),
                       let tag = try? JSONDecoder().decode(Tag.self, from: data),
                       tag.attributes?.isChild == false {
                        // Now, only first level parent tags are considered
                        allParentTags.append(tag)
                    }
                }
            }
        }
        return (allTags, allParentTags)
    }
}

class TagViewModel {
    var id: String
    var name: String
    var backgroundColor: Color
    var child: TagViewModel?
    var iconInfo: (icon: FontAwesome, style: FontAwesomeStyle)?

    init(tag: Tag, parentTag: Tag? = nil) {
        var currentLevelTag = tag
        if let parentTag = parentTag {
            child = TagViewModel(tag: tag)
            currentLevelTag = parentTag
        }

        id = currentLevelTag.id
        name = currentLevelTag.attributes?.name ?? "Unkown"
        var colorProp = currentLevelTag.attributes?.color
        if colorProp == nil || colorProp == "" {
            colorProp = "#E8E8E8"
        }
        backgroundColor = Color(rgba: colorProp!)
        if let iconStr = currentLevelTag.attributes?.icon, iconStr != "" {
            // e.g, "fas fa-water", "fas fa-exclamation-triangle"
            var faStyle: FontAwesomeStyle = .solid
            let splitResult = iconStr.split(separator: " ")
            if splitResult.count == 2 {
                if splitResult.first == "fas" {
                    faStyle = .solid
                } else if splitResult.first == "far" {
                    faStyle = .regular
                } else if splitResult.first == "fal" {
                    faStyle = .light
                } else if splitResult.first == "fab" {
                    faStyle = .brands
                }
            }

            for i in FontAwesome.allCases {
                if let last = splitResult.last,
                   i.rawValue == last {
                    if i.isSupported(style: faStyle) {
                        iconInfo = (i, faStyle)
                    } else {
                        iconInfo = (i, i.supportedStyles.first!)
                    }
                    break
                }
            }
        }
    }
}

extension TagViewModel: Equatable {
    static func == (lhs: TagViewModel, rhs: TagViewModel) -> Bool {
        lhs.id == rhs.id
    }
}

class TagsViewModel: ObservableObject {
    @Published var allTags: [TagViewModel] = []
    @Published var allParentTags: [TagViewModel] = []

    static let shared = TagsViewModel()
}
