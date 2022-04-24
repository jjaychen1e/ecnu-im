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

class TagViewModel {
    var id: String
    var name: String
    var backgroundColor: Color
    var child: TagViewModel?
    var iconInfo: (icon: FontAwesome, style: FontAwesomeStyle)?
    var fontColor: Color?

    init(tag: FlarumTag, child: TagViewModel? = nil) {
        self.child = child
        
        id = tag.id
        name = tag.attributes.name
        var colorProp = tag.attributes.color
        if colorProp == "" {
            colorProp = "#E4EBF6"
            fontColor = Color(rgba: "#667A99")
        }
        backgroundColor = Color(rgba: colorProp)
        let iconStr = tag.attributes.icon
        if iconStr != "" {
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
    @Published var tags: [TagViewModel] = []

    static let shared = TagsViewModel()
}
