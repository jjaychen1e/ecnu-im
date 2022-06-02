//
//  MiniEditor.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/14.
//

import Combine
import SwiftUI

class EditorContentModel: ObservableObject {
    @Published var text = ""
}

class MiniEditorViewModel: ObservableObject {
    @Published var focused: Bool = false
    @Published var discussion: FlarumDiscussion
    @Published var replyTarget: ReplyTarget?

    var isEditing: Bool {
        focused
    }

    var contentModel: EditorContentModel?

    enum ReplyTarget: Hashable {
        case discussion(FlarumDiscussion)
        case post(FlarumPost)
        case edit(FlarumPost)
    }

    var contentCache: [ReplyTarget: String] = [:]
    var showCallback: () -> Void
    var hideCallback: () -> Void
    var didPostCallback: (FlarumPost) -> Void

    func show(target: ReplyTarget) {
        if let replyTarget = replyTarget {
            // Directly switched from another reply
            if let contentModel = contentModel {
                // we should store the content
                contentCache[replyTarget] = contentModel.text
                contentModel.text = ""
            }
            self.replyTarget = nil
        }

        replyTarget = target
        if let contentModel = contentModel, let replyTarget = replyTarget {
            switch replyTarget {
            case .discussion, .post:
                contentModel.text = contentCache[replyTarget] ?? ""
            case let .edit(flarumPost):
                if let content = flarumPost.attributes?.content, case let .comment(postContent) = content {
                    contentModel.text = postContent
                } else {
                    fatalErrorDebug()
                }
            }
        }

        focused = true
        showCallback()
    }

    func hide() {
        if let contentModel = contentModel, let replyTarget = replyTarget {
            switch replyTarget {
            case .discussion, .post:
                contentCache[replyTarget] = contentModel.text
            case .edit:
                break
            }
            contentModel.text = ""
            self.replyTarget = nil
        }
        focused = false
        hideCallback()
    }

    init(discussion: FlarumDiscussion, contentModel: EditorContentModel? = nil, showCallback: @escaping () -> Void, hideCallback: @escaping () -> Void, didPostCallback: @escaping (FlarumPost) -> Void) {
        self.discussion = discussion
        self.contentModel = contentModel
        self.showCallback = showCallback
        self.hideCallback = hideCallback
        self.didPostCallback = didPostCallback
    }
}

struct MiniEditor: View {
    @State var discussion: FlarumDiscussion
    @ObservedObject private var contentViewModel = EditorContentModel()
    @ObservedObject var viewModel: MiniEditorViewModel

    @State private var sending = false
    @FocusState private var focus: Bool

    init(discussion: FlarumDiscussion, textFieldVM: MiniEditorViewModel) {
        self.discussion = discussion
        viewModel = textFieldVM
        viewModel.contentModel = contentViewModel
    }

    var body: some View {
        Asset.DynamicColors.dynamicWhite.swiftUIColor
            .frame(height: 200)
            .overlay(
                mainArea
            )
            .overlay(alignment: .bottom) {
                // To fill the safe area...
                Asset.DynamicColors.dynamicWhite.swiftUIColor.frame(height: 1000)
                    .offset(x: 0, y: 1000)
            }
            .onChange(of: viewModel.focused) {
                // FocusState is a in-view property wrapper... Hard to use subscriptions(without memory leak)
                focus = $0
            }
            .onChange(of: focus) {
                viewModel.focused = $0
            }
    }

    var mainArea: some View {
        VStack(alignment: .leading, spacing: 6) {
            Color.primary.opacity(0.1)
                .frame(height: 1)
                .frame(maxWidth: .infinity)
            replyTargetHint()
            mainEditor
            toolBar
        }
        .padding(.bottom)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func replyTargetHint() -> some View {
        let target: String = {
            switch viewModel.replyTarget {
            case let .discussion(discussion):
                return "正在回复主题 - \(discussion.discussionTitle)"
            case let .post(post):
                return "正在回复 @\(post.authorName) - 帖子#\(post.attributes?.number ?? -1)"
            case let .edit(post):
                return "正在编辑 @\(post.authorName) - 帖子#\(post.attributes?.number ?? -1)"
            case .none:
                return ""
            }
        }()

        Text(target)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundColor(.primary.opacity(0.8))
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.1))
            .cornerRadius(4)
    }

    var mainEditor: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Asset.DynamicColors.dynamicBlack.swiftUIColor.opacity(0.1), lineWidth: 1)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Asset.DynamicColors.dynamicWhite.swiftUIColor)
            )
            .overlay(
                TextEditor(text: $contentViewModel.text)
                    .focused($focus)
                    .padding(.all, 4)
            )
    }

    var toolBar: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 4) {
                    Button {} label: {
                        ZStack {
                            Color.clear
                            Image(systemName: "photo.fill")
                                .font(.system(size: 20))
                                .frame(width: 30, height: 30)
                        }
                    }
                    .disabled(true)
                    .opacity(0.3)

                    Button {} label: {
                        ZStack {
                            Color.clear
                            Text("#")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .frame(width: 30, height: 30)
                        }
                    }
                    .disabled(true)
                    .opacity(0.3)

                    Button {} label: {
                        ZStack {
                            Color.clear
                            Text("#")
                                .font(.system(size: 25, weight: .medium, design: .rounded))
                                .frame(width: 30, height: 30)
                        }
                    }
                    .disabled(true)
                    .opacity(0.3)

                    Button {} label: {
                        ZStack {
                            Color.clear
                            Image(systemName: "bold")
                                .font(.system(size: 25))
                                .frame(width: 30, height: 30)
                        }
                    }
                    .disabled(true)
                    .opacity(0.3)

                    Button {} label: {
                        ZStack {
                            Color.clear
                            Image(systemName: "italic")
                                .font(.system(size: 25))
                                .frame(width: 30, height: 30)
                        }
                    }
                    .disabled(true)
                    .opacity(0.3)

                    Button {} label: {
                        ZStack {
                            Color.clear
                            Image(systemName: "underline")
                                .font(.system(size: 25))
                                .frame(width: 30, height: 30)
                        }
                    }
                    .disabled(true)
                    .opacity(0.3)

                    Button {} label: {
                        ZStack {
                            Color.clear
                            Image(systemName: "strikethrough")
                                .font(.system(size: 25))
                                .frame(width: 30, height: 30)
                        }
                    }
                    .disabled(true)
                    .opacity(0.3)

                    Button {
                        UIApplication.shared
                            .presentOnTop(UIHostingController(rootView: EditorView(model: contentViewModel)), animated: true)
                    } label: {
                        ZStack {
                            Color.clear
                            Image(systemName: "bolt")
                                .font(.system(size: 22))
                                .frame(width: 30, height: 30)
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
            .frame(height: 30)
            .foregroundColor(Asset.DynamicColors.dynamicBlack.swiftUIColor)

            Button("取消") {
                viewModel.hide()
            }

            Button("发送") {
                Task {
                    var content = contentViewModel.text
                    if case let .post(post) = viewModel.replyTarget {
                        content = "@\"\(post.authorName)\"#p\(post.id) " + content
                    }

                    sending = true
                    if let response = try? await flarumProvider.request(.newPost(discussionID: discussion.id, content: content)).flarumResponse() {
                        if let post = response.data.posts.first {
                            self.viewModel.didPostCallback(post)
                            let toast = Toast.default(
                                icon: .emoji("✅"),
                                title: "发表成功"
                            )
                            toast.show()
                            contentViewModel.text = ""
                            viewModel.hide()
                        } else {
                            let toast = Toast.default(
                                icon: .emoji("🤨"),
                                title: "发表失败，请再试一次"
                            )
                            toast.show()
                        }
                        sending = false
                    }
                }
            }
            .disabled(sending)
            .overlay(
                Group {
                    if sending {
                        ProgressView()
                    }
                },
                alignment: .center
            )
        }
    }
}
