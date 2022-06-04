//
//  DiscussionTagsView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/24.
//

import SwiftUI

struct DiscussionTagsView: View {
    @Binding var tags: [TagViewModel]
    @State var fontSize: CGFloat = 12
    @State var horizontalPadding: CGFloat = 5
    @State var verticalPadding: CGFloat = 4
    @State var cornerRadius: CGFloat = 4
    @State var spacing: CGFloat = 2

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
            .mask(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            EmptyView()
        }
    }

    func singleTagView(tag: TagViewModel) -> some View {
        HStack(spacing: spacing) {
            if let iconInfo = tag.iconInfo {
                Text(fa: iconInfo.icon, faStyle: iconInfo.style, size: fontSize)
                    .lineLimit(1)
            }
            Text(tag.name)
                .font(.system(size: fontSize))
                .lineLimit(1)
        }
        .foregroundColor(tag.fontColor ?? .primary)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(tag.backgroundColor)
    }
}

struct DiscussionTagsView_Previews: PreviewProvider {
    static var previews: some View {
        let podcastTag = TagViewModel(tag: .init(id: "1", attributes: .init(name: "播客", description: "", slug: "", color: "", icon: "", discussionCount: 0, isChild: false, isHidden: false, lastPostedAt: "", canStartDiscussion: true, canAddToDiscussion: true)))
        let chitChatTag = TagViewModel(tag: .init(id: "1", attributes: .init(name: "灌水闲聊", description: "", slug: "", color: "#42A5F5", icon: "fas fa-water", discussionCount: 0, isChild: false, isHidden: false, lastPostedAt: "", canStartDiscussion: true, canAddToDiscussion: true)),
                                       child: podcastTag)
        let eliteTag = TagViewModel(tag: .init(id: "1", attributes: .init(name: "精华", description: "", slug: "", color: "#FFCA28", icon: "fas fa-star", discussionCount: 0, isChild: false, isHidden: false, lastPostedAt: "", canStartDiscussion: true, canAddToDiscussion: true)))
        DiscussionTagsView(tags: .constant([
            chitChatTag,
            eliteTag,
        ]))
    }
}
