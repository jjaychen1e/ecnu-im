//
//  DiscussionTagsView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/24.
//

import SwiftUI

struct DiscussionTagsView: View {
    private let tags: [TagViewModel]

    init(tags: [TagViewModel]) {
        self.tags = tags
    }

    var body: some View {
        if tags.count > 0 {
            HStack(spacing: 0) {
                ForEach(Array(zip(tags.indices, tags)), id: \.1.id) { index, tag in
                    Group {
                        singleTagView(tag: tag)
                        if let childTag = tag.child {
                            singleTagView(tag: childTag)
                        }
                    }
                }
            }
            .mask(RoundedRectangle(cornerRadius: 5, style: .continuous))
        } else {
            EmptyView()
        }
    }

    func singleTagView(tag: TagViewModel) -> some View {
        HStack(spacing: 2) {
            if let iconInfo = tag.iconInfo {
                Text(fa: iconInfo.icon, faStyle: iconInfo.style, size: 12)
            }
            Text(tag.name)
                .font(.system(size: 12))
        }
        .foregroundColor(tag.fontColor ?? .primary)
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
        .background(tag.backgroundColor)
    }
}

struct DiscussionTagsView_Previews: PreviewProvider {
    static var previews: some View {
        let podcastTag = TagViewModel(tag: .init(id: "1", attributes: .init(name: "播客", description: "", slug: "", color: "", icon: "", discussionCount: 0, isChild: false, isHidden: false, lastPostedAt: "", canStartDiscussion: true, canAddToDiscussion: true)))
        let chitChatTag = TagViewModel(tag: .init(id: "1", attributes: .init(name: "灌水闲聊", description: "", slug: "", color: "#42A5F5", icon: "fas fa-water", discussionCount: 0, isChild: false, isHidden: false, lastPostedAt: "", canStartDiscussion: true, canAddToDiscussion: true)),
                                       child: podcastTag)
        let eliteTag = TagViewModel(tag: .init(id: "1", attributes: .init(name: "精华", description: "", slug: "", color: "#FFCA28", icon: "fas fa-star", discussionCount: 0, isChild: false, isHidden: false, lastPostedAt: "", canStartDiscussion: true, canAddToDiscussion: true)))
        DiscussionTagsView(tags: [
            chitChatTag,
            eliteTag,
        ])
    }
}
