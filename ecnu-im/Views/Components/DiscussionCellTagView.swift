//
//  DiscussionCellTagView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/28.
//

import FontAwesome
import Foundation
import SwiftUI

struct DiscussionCellTagView: View {
    @EnvironmentObject var tagsViewModel: TagsViewModel

    private let tag: TagViewModel

    init(tag: TagViewModel) {
        self.tag = tag
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 2) {
                if let iconInfo = tag.iconInfo {
                    Text(fa: iconInfo.icon, faStyle: iconInfo.style, size: 14)
                }
                Text(tag.name)
                    .font(.system(size: 14))
            }
            .padding(.vertical, 2)
            .padding(.leading, 6)
            .padding(.trailing, tag.child == nil ? 6 : 2)
            .background(tag.backgroundColor)
            if let childTag = tag.child {
                HStack(spacing: 2) {
                    if let iconInfo = childTag.iconInfo {
                        Text(fa: iconInfo.icon, faStyle: iconInfo.style, size: 14)
                    }
                    Text(childTag.name)
                        .font(.system(size: 14))
                }
                .padding(.vertical, 2)
                .padding(.leading, 2)
                .padding(.trailing, 6)
                .background(childTag.backgroundColor)
            }
        }
        .cornerRadius(4)
    }
}
