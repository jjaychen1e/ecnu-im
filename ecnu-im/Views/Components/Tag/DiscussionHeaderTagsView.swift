//
//  DiscussionHeaderTagsView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/24.
//

import SwiftSoup
import SwiftUI

struct DiscussionHeaderTagsView: View {
    private let tags: [TagViewModel]

    init(tags: [TagViewModel]) {
        self.tags = tags
    }

    var body: some View {
        if tags.count > 0 {
            HStack(spacing: 0) {
                ForEach(Array(zip(tags.indices, tags)), id: \.1.id) { index, tag in
                    Group {
                        singleTagView(tag: tag, drawSeparator: index != 0)
                        if let childTag = tag.child {
                            singleTagView(tag: childTag, drawSeparator: true)
                        }
                    }
                }
            }
            .cornerRadius(6)
        } else {
            EmptyView()
        }
    }

    func singleTagView(tag: TagViewModel, drawSeparator: Bool) -> some View {
        HStack(spacing: 2) {
            if let iconInfo = tag.iconInfo {
                Text(fa: iconInfo.icon, faStyle: iconInfo.style, size: 14)
            }
            Text(tag.name)
                .font(.system(size: 14))
        }
        .foregroundColor(tag.fontColor ?? tag.backgroundColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Asset.DynamicColors.dynamicWhite.swiftUIColor)
        .overlay(
            Group {
                if drawSeparator {
                    Color.primary.opacity(0.3).frame(width: 0.5)
                }
            },
            alignment: .leading
        )
    }
}
