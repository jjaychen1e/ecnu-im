//
//  DiscussionHeaderView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/30.
//

import SwiftUI

class DiscussionHeaderViewModel: ObservableObject {
    @Published var discussion: FlarumDiscussion

    init(discussion: FlarumDiscussion) {
        self.discussion = discussion
    }
}

struct DiscussionHeaderView: View {
    @EnvironmentObject var uiKitEnvironment: UIKitEnvironment
    @ObservedObject private var viewModel: DiscussionHeaderViewModel

    init(viewModel: DiscussionHeaderViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Group {
                if viewModel.discussion.synthesizedTags.count > 0 {
                    DiscussionHeaderTagsView(tags: viewModel.discussion.synthesizedTags)
                }
                Text(viewModel.discussion.discussionTitle)
                    .font(.system(size: 20, weight: .medium, design: .default))
                    .padding(.horizontal, viewModel.discussion.synthesizedTags.count == 0 ? 30 : 0)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, minHeight: 50, alignment: .bottom)
        .foregroundColor(Asset.DynamicColors.dynamicWhite.swiftUIColor)
        .background(viewModel.discussion.synthesizedTags.first?.backgroundColor ?? .init(uiColor: UIColor.gray))
        .overlay(
            Group {
                if let splitVC = uiKitEnvironment.splitVC,
                   let nvc = uiKitEnvironment.nvc {
                    Button(action: {
                        splitVC.pop(from: nvc)
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
