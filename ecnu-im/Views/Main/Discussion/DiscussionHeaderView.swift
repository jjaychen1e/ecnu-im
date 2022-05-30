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
                if viewModel.discussion.tagViewModels.count > 0 {
                    DiscussionHeaderTagsView(tags: viewModel.discussion.tagViewModels)
                }
                Text(viewModel.discussion.discussionTitle)
                    .font(.system(size: 20, weight: .medium, design: .default))
                    .padding(.horizontal, viewModel.discussion.tagViewModels.count == 0 ? 30 : 0)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, minHeight: 50, alignment: .bottom)
        .foregroundColor(Asset.DynamicColors.dynamicWhite.swiftUIColor)
        .background(viewModel.discussion.tagViewModels.first?.backgroundColor ?? .init(uiColor: UIColor.gray))
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
        .overlay(
            PopoverMenu {
                PopoverMenuItem(title: "App 问题反馈", systemImage: "exclamationmark.bubble", action: {})
                    .disabled(true)
                PopoverMenuItem(title: "分享", systemImage: "square.and.arrow.up", action: {})
                    .disabled(true)

                if let url = URL(string: URLService.link(href: "https://ecnu.im/d/\(viewModel.discussion.id)").url) {
                    PopoverMenuItem(title: "打开网页版", systemImage: "safari", action: {
                        UIApplication.shared.open(url)
                    })
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(Asset.DynamicColors.dynamicWhite.swiftUIColor)
            }
            .offset(x: -8, y: 0),
            alignment: .bottomTrailing
        )
    }
}
