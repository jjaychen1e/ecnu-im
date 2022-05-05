//
//  DiscussionHeaderView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/30.
//

import SwiftUI

struct DiscussionHeaderView: View {
    @Environment(\.splitVC) var splitVC
    @Environment(\.nvc) var nvc
    @State private var discussion: FlarumDiscussion

    init(discussion: FlarumDiscussion) {
        _discussion = State(initialValue: discussion)
    }

    var body: some View {
        VStack {
            Group {
                if discussion.synthesizedTags.count > 0 {
                    DiscussionHeaderTagsView(tags: discussion.synthesizedTags)
                }
                Text(discussion.discussionTitle)
                    .font(.system(size: 20, weight: .medium, design: .default))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
        .padding(.top, 8)
        .frame(maxWidth: .infinity)
        .foregroundColor(Asset.DynamicColors.dynamicWhite.swiftUIColor)
        .background(discussion.synthesizedTags.first?.backgroundColor ?? .init(uiColor: UIColor.gray))
        .overlay(
            Group {
                if let splitVC = splitVC {
                    Button(action: {
                        if let nvc = nvc {
                            if nvc.viewControllers.count == 1 {
                                splitVC.show(.primary)
                            } else {
                                nvc.popViewController(animated: true)
                            }
                        }
                    }, label: {
                        Image(systemName: "arrow.backward.circle.fill")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(Asset.DynamicColors.dynamicWhite.swiftUIColor)
                    })
                    .offset(x: 8, y: 0)
                }
            },
            alignment: .topLeading
        )
    }
}
