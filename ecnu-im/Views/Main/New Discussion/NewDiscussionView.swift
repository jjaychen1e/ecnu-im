//
//  NewDiscussionView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/23.
//

import SwiftUI

class TagPair: Equatable {
    static func == (lhs: TagPair, rhs: TagPair) -> Bool {
        lhs.parent == rhs.parent && lhs.children == rhs.children
    }

    var parent: FlarumTag
    var children: [FlarumTag]

    init(parent: FlarumTag, children: [FlarumTag] = []) {
        self.parent = parent
        self.children = children
    }

    var allFlarumTags: [FlarumTag] {
        [parent] + children
    }
}

struct NewDiscussionTagChooseView: View {
    @ObservedObject var viewModel: NewDiscussionTagChooseViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                let positionedTag = viewModel.tagPairs.filter { $0.parent.attributes.position != nil }
                let nonPositionedTag = viewModel.tagPairs.filter { $0.parent.attributes.position == nil }
                Section(header: Text("已选择")) {
                    let tags: [FlarumTag] = viewModel.allFlarumTags
                    Group {
                        if tags.count > 0 {
                            let viewModels = tags.mappedTagViewModels
                            DiscussionTagsView(tags: .constant(viewModels), fontSize: 14)
                                .fixedSize()
                        } else {
                            Text("暂无选择的标签")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                        }
                    }
                    .transition(.opacity)
                }

                Section(header: Text("普通标签")) {
                    ForEach(0 ..< positionedTag.count, id: \.self) { index in
                        let tagPair = positionedTag[index]
                        let children = tagPair.children
                        if children.count > 0 {
                            DisclosureGroup {
                                // Tag self
                                Group {
                                    let tagPairForParentOnly = TagPair(parent: tagPair.parent, children: [])
                                    let checked = viewModel.selectedNormalTag == tagPairForParentOnly
                                    HStack {
                                        let viewModels = [tagPairForParentOnly.parent].mappedTagViewModels
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
                                        if viewModel.selectedNormalTag == tagPairForParentOnly {
                                            // Already selected
                                            viewModel.selectedNormalTag = nil
                                        } else {
                                            viewModel.selectedNormalTag = tagPairForParentOnly
                                        }
                                    }
                                }
                                ForEach(0 ..< children.count, id: \.self) { index in
                                    let child = children[index]
                                    let tagPairForChild = TagPair(parent: tagPair.parent, children: [child])
                                    let checked = viewModel.selectedNormalTag == tagPairForChild
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
                                    .onTapGesture {
                                        if viewModel.selectedNormalTag == tagPairForChild {
                                            // Already selected
                                            viewModel.selectedNormalTag = nil
                                        } else {
                                            viewModel.selectedNormalTag = tagPairForChild
                                        }
                                    }
                                }
                            } label: {
                                let viewModels = [tagPair.parent].mappedTagViewModels
                                DiscussionTagsView(tags: .constant(viewModels), fontSize: 14)
                                    .fixedSize()
                            }
                        } else {
                            let checked = viewModel.selectedNormalTag == tagPair
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
                                if viewModel.selectedNormalTag == tagPair {
                                    // Already selected
                                    viewModel.selectedNormalTag = nil
                                } else {
                                    viewModel.selectedNormalTag = tagPair
                                }
                            }
                        }
                    }
                }

                Section(header: Text("特殊标签")) {
                    ForEach(0 ..< nonPositionedTag.count, id: \.self) { index in
                        let tagPair = nonPositionedTag[index]
                        let checked = viewModel.selectedSpecialTags.contains(where: { $0.id == tagPair.parent.id })
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
                            if let _ = viewModel.selectedSpecialTags.first(where: { $0.id == tagPair.parent.id }) {
                                // Already selected
                                viewModel.selectedSpecialTags.removeAll(where: { $0.id == tagPair.parent.id })
                            } else {
                                viewModel.selectedSpecialTags.append(tagPair.parent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("标签列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("完成")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                }
            }
        }
    }
}

class NewDiscussionTagChooseViewModel: ObservableObject {
    @Published var tagPairs: [TagPair] = []
    @Published var showTagChooseView = false
    @Published var selectedSpecialTags: [FlarumTag] = []
    @Published var selectedNormalTag: TagPair?

    var allFlarumTags: [FlarumTag] {
        selectedSpecialTags + (selectedNormalTag?.allFlarumTags ?? [])
    }
}

struct NewDiscussionView: View {
    @Environment(\.dismiss) var dismiss

    @State var title = ""
    @State var postContent = ""
    @State var sending = false
    @FocusState var focused: Bool

    @ObservedObject var tagChooseViewModel = NewDiscussionTagChooseViewModel()

    var body: some View {
        NavigationView {
            VStack {
                HStack(alignment: .top) {
                    PostAuthorAvatarView(name: AppGlobalState.shared.userInfo?.attributes.displayName ?? "Unknown", url: AppGlobalState.shared.userInfo?.avatarURL, size: 40)
                    VStack(alignment: .leading) {
                        TextField("标题", text: $title)
                            .font(.system(size: 15, weight: .medium, design: .rounded))

                        Button {
                            tagChooseViewModel.showTagChooseView = true
                        } label: {
                            let tags: [FlarumTag] = tagChooseViewModel.allFlarumTags
                            if tags.count > 0 {
                                let viewModels = tags.mappedTagViewModels
                                DiscussionTagsView(tags: .constant(viewModels))
                                    .fixedSize()
                            } else {
                                Text("添加标签")
                                    .foregroundColor(.init(rgba: "#667A99"))
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .padding(.all, 4)
                                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(Color(rgba: "#667A99")))
                            }
                        }
                        .buttonStyle(.plain)
//                    Text("发起投票")
                    }
                }

                TextEditor(text: $postContent)
                    .focused($focused)
                    .disableAutocorrection(true)
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .frame(maxHeight: .infinity)
                    .overlay(
                        Group {
                            if focused == false, postContent == "" {
                                Text("说点什么吧...")
                                    .font(.system(size: 14, weight: .regular, design: .default))
                                    .foregroundColor(Color.primary.opacity(0.4))
                                    .padding(.top, 8)
                            }
                        },
                        alignment: .topLeading
                    )
            }
            .padding()
            .sheet(isPresented: $tagChooseViewModel.showTagChooseView) {
                NewDiscussionTagChooseView(viewModel: tagChooseViewModel)
            }
            .onLoad {
                Task {
                    if let response = try? await flarumProvider.request(.allTags).flarumResponse() {
                        let tags = response.data.tags
                        var tagPairs: [TagPair] = []
                        let parents = tags.filter { $0.attributes.isChild == false }
                        tagPairs.append(contentsOf: parents.map { TagPair(parent: $0, children: []) })
                        for tag in tags where tag.attributes.isChild == true {
                            if let tagPair = tagPairs.first(where: { $0.parent.id == tag.relationships?.parent?.id }) {
                                tagPair.children.append(tag)
                            }
                        }

                        tagPairs.sort { tagPair1, tagPair2 in
                            if let position1 = tagPair1.parent.attributes.position, let position2 = tagPair2.parent.attributes.position {
                                return position1 < position2
                            } else if let _ = tagPair1.parent.attributes.position {
                                return true
                            } else if let _ = tagPair2.parent.attributes.position {
                                return false
                            } else {
                                return false
                            }
                        }

                        tagChooseViewModel.tagPairs = tagPairs
                    }
                }
            }
            .navigationTitle("新话题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("取消")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            sending = true
                            if let response = try? await flarumProvider.request(.newDiscussion(title: title, content: postContent, tagIds: tagChooseViewModel.allFlarumTags.map { $0.id })) {
                                sending = false
                                if let errorModel = try? response.map(FlarumAPIErrorModel.self) {
                                    if let error = errorModel.errors.first {
                                        Toast.default(icon: .emoji("❌"), title: "发布失败", subtitle: error.detail).show()
                                    }
                                } else {
                                    let flarumResponse = response.flarumResponse()
                                    if let _ = flarumResponse.data.discussions.first {
                                        Toast.default(icon: .emoji("🎉"), title: "发布成功").show()
                                        dismiss()
                                    }
                                }
                            }
                        }
                    } label: {
                        Text("发布")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .overlay(
                                Group {
                                    if sending {
                                        ProgressView()
                                    }
                                },
                                alignment: .center
                            )
                    }
                    .disabled(sending)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct NewDiscussionView_Previews: PreviewProvider {
    static var previews: some View {
        NewDiscussionView()
    }
}
