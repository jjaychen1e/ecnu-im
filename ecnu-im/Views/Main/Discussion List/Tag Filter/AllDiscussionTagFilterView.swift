//
//  AllDiscussionTagFilterView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/6/3.
//

import Combine
import SwiftUI

class AllDiscussionTagFilterViewModel: ObservableObject {
    @Published var tagPairs: [TagPair] = []
    @Published var showTagChooseView = false
    @Published var selectedNormalTags: [FlarumTag] = []
    @Published var selectedParentTags: [FlarumTag] = []

    var confirmPublisher = PassthroughSubject<[FlarumTag], Never>()

    var allFlarumTags: [FlarumTag] {
        selectedParentTags + selectedNormalTags
    }
}

struct AllDiscussionTagFilterView: View {
    @ObservedObject var viewModel: AllDiscussionTagFilterViewModel

    @EnvironmentObject var uiKitEnvironment: UIKitEnvironment

    var body: some View {
        List {
            let positionedTag = viewModel.tagPairs.filter { $0.parent.attributes.position != nil }
            let nonPositionedTag = viewModel.tagPairs.filter { $0.parent.attributes.position == nil }
            Section(header: Text("已选择")) {
                let tags: [FlarumTag] = viewModel.allFlarumTags
                let items: [GridItem] = Array(repeating: GridItem(.fixed(24), alignment: .leading), count: 3)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: items, spacing: 8) {
                        ForEach(Array(zip(tags.indices, tags)), id: \.1.id) { index, tag in
                            let viewModels = ([tag] + [tag].compactMap { $0.relationships?.parent }).mappedTagViewModels
                            DiscussionTagsView(tags: .constant(viewModels), fontSize: 14)
                                .fixedSize()
                                .transition(.opacity)
                        }
                    }
                }
                .overlay {
                    Text("暂无选择的标签")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .opacity(tags.count == 0 ? 1.0 : 0.0)
                }
            }

            Section(header: Text("普通标签")) {
                ForEach(0 ..< positionedTag.count, id: \.self) { index in
                    let tagPair = positionedTag[index]
                    let children = tagPair.children
                    if children.count > 0 {
                        DisclosureGroup {
                            // Tag self
                            Group {
                                let tag = tagPair.parent
                                let checked = viewModel.selectedParentTags.contains(tag)
                                HStack {
                                    let viewModels = [tag].mappedTagViewModels
                                    DiscussionTagsView(tags: .constant(viewModels), fontSize: 14)
                                        .fixedSize()
                                    Spacer(minLength: 0)
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.primary.opacity(0.7))
                                        .opacity(checked ? 1.0 : 0.0)
                                        .animation(.default, value: checked)
                                }
                                .background(Color.primary.opacity(0.0001))
                                .onTapGesture {
                                    withAnimation {
                                        if checked {
                                            // Already selected
                                            viewModel.selectedParentTags.removeAll(where: { $0.id == tag.id })
                                        } else {
                                            viewModel.selectedParentTags.append(tag)
                                        }
                                        viewModel.selectedNormalTags.removeAll(where: { $0.relationships?.parent?.id == tag.id })
                                    }
                                }
                            }
                            ForEach(0 ..< children.count, id: \.self) { index in
                                let child = children[index]
                                let tagPairForChild = TagPair(parent: tagPair.parent, children: [child])
                                let isParentChecked = viewModel.selectedParentTags.contains(tagPair.parent)
                                let checked = viewModel.selectedNormalTags.contains(child) || isParentChecked
                                HStack {
                                    let viewModels = tagPairForChild.allFlarumTags.mappedTagViewModels
                                    DiscussionTagsView(tags: .constant(viewModels), fontSize: 14)
                                        .fixedSize()
                                    Spacer(minLength: 0)
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.primary.opacity(0.7))
                                        .opacity(checked ? 1.0 : 0.0)
                                        .animation(.default, value: checked)
                                }
                                .background(Color.primary.opacity(0.0001))
                                .opacity(isParentChecked ? 0.5 : 1.0)
                                .onTapGesture {
                                    withAnimation {
                                        if !isParentChecked {
                                            if checked {
                                                // Already selected
                                                viewModel.selectedNormalTags.removeAll(where: { $0.id == child.id })
                                            } else {
                                                viewModel.selectedNormalTags.append(child)
                                            }
                                        }
                                    }
                                }
                            }
                        } label: {
                            let viewModels = [tagPair.parent].mappedTagViewModels
                            DiscussionTagsView(tags: .constant(viewModels), fontSize: 14)
                                .fixedSize()
                        }
                    } else {
                        let tag = tagPair.parent
                        let checked = viewModel.selectedParentTags.contains(tag)
                        HStack {
                            let viewModels = [tagPair.parent].mappedTagViewModels
                            DiscussionTagsView(tags: .constant(viewModels), fontSize: 14)
                                .fixedSize()
                            Spacer(minLength: 0)
                            Image(systemName: "checkmark")
                                .foregroundColor(.primary.opacity(0.7))
                                .opacity(checked ? 1.0 : 0.0)
                                .animation(.default, value: checked)
                        }
                        .background(Color.primary.opacity(0.0001))
                        .onTapGesture {
                            withAnimation {
                                if checked {
                                    // Already selected
                                    viewModel.selectedParentTags.removeAll(where: { $0.id == tag.id })
                                } else {
                                    viewModel.selectedParentTags.append(tag)
                                }
                            }
                        }
                    }
                }
            }

            Section(header: Text("特殊标签")) {
                ForEach(0 ..< nonPositionedTag.count, id: \.self) { index in
                    let tagPair = nonPositionedTag[index]
                    let checked = viewModel.selectedNormalTags.contains(where: { $0.id == tagPair.parent.id })
                    HStack {
                        let viewModels = [tagPair.parent].mappedTagViewModels
                        DiscussionTagsView(tags: .constant(viewModels), fontSize: 14)
                            .fixedSize()
                        Spacer(minLength: 0)
                        Image(systemName: "checkmark")
                            .foregroundColor(.primary.opacity(0.7))
                            .opacity(checked ? 1.0 : 0.0)
                            .animation(.default, value: checked)
                    }
                    .background(Color.primary.opacity(0.0001))
                    .onTapGesture {
                        withAnimation {
                            if checked {
                                // Already selected
                                viewModel.selectedNormalTags.removeAll(where: { $0.id == tagPair.parent.id })
                            } else {
                                viewModel.selectedNormalTags.append(tagPair.parent)
                            }
                        }
                    }
                }
            }
        }
        .onDoneDismiss { [weak viewModel] in
            if let viewModel = viewModel {
                viewModel.confirmPublisher.send(viewModel.allFlarumTags)
            }
        }
        .navigationTitle("标签列表")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    uiKitEnvironment.navWrapperVC?.dismiss(animated: true)
                } label: {
                    Text("取消")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                }
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    withAnimation {
                        viewModel.selectedParentTags = []
                        viewModel.selectedNormalTags = []
                    }
                } label: {
                    Text("清除")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                }
            }
        }
    }
}
