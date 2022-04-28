//
//  DiscussionView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/31.
//

import Regex
import SwiftUI
import SwiftyJSON

private struct DiscussionViewPostCell: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var post: FlarumPost
    @State private var index: Int

    var contentString: String {
        if let content = post.attributes?.content,
           case let .comment(comment) = content {
            return comment
        }
        return ""
    }

    init(post: FlarumPost, index: Int) {
        _post = State(wrappedValue: post)
        _index = State(wrappedValue: index)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                PostAuthorAvatarView(name: post.authorName, url: post.authorAvatarURL, size: 40)
                VStack(alignment: .leading) {
                    HStack {
                        Text(post.authorName)
                            .font(.system(size: 12, weight: .medium))
                        Text(post.createdDateDescription)
                            .font(.system(size: 10, weight: .light))
                        Text("#\(post.attributes?.number ?? -1)")
                    }
                }
                Spacer()
            }
            PostContentView(content: contentString)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .tag(index)
    }
}

private struct DiscussionViewPostCellPlaceholder: View {
    @State private var index: Int
    init(index: Int) {
        self.index = index
    }

    var body: some View {
        VStack {
            HStack {
                Circle()
                    .fill(Color(rgba: "#D6D6D6"))
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading) {
                    HStack {
                        Text("jjaychen")
                            .font(.system(size: 12, weight: .medium))
                        Text("1 分钟前")
                            .font(.system(size: 10, weight: .light))
                        Text("#\(index)")
                    }
                }
                Spacer()
            }
            Text(String(repeating: "那只敏捷的棕毛狐狸跳过那只懒狗，消失得无影无踪。", count: 10))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .tag(index)
        .redacted(reason: .placeholder)
    }
}

private struct DiscussionViewHeader: View {
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
                } else {
                    Color.clear
                        .frame(height: 30)
                }
                Text(discussion.discussionTitle)
                    .font(.system(size: 20, weight: .medium, design: .default))
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
        .padding(.top, 8)
        .frame(maxWidth: .infinity)
        .foregroundColor(Asset.DynamicColors.dynamicWhite.swiftUIColor)
        .background(discussion.synthesizedTags.first?.backgroundColor ?? .gray)
        .overlay(
            Group {
                if let splitVC = splitVC {
                    if splitVC.traitCollection.horizontalSizeClass == .compact {
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
                }
            },
            alignment: .topLeading
        )
    }
}

struct ScrollTarget: Equatable {
    let id: Int
    let anchor: UnitPoint
}

class DumbPublisher: ObservableObject {
    @Published var publishedValue = 0
}

struct DiscussionView: View {
    @State private var miniMiniEditorDisplayed = false
    @FocusState private var miniMiniEditorFocused: Bool

    @State private var posts: [FlarumPost?] = []
    @State private var scrollTarget: ScrollTarget?
    @State private var discussion: FlarumDiscussion
    @State private var near: Int
    @ObservedObject private var loader: DiscussionPostsLoader

    private let limit = 30

    var discussionID: Int {
        Int(discussion.id)!
    }

    init(discussion: FlarumDiscussion, near: Int) {
        _discussion = State(initialValue: discussion)
        _near = State(initialValue: near)
        loader = DiscussionPostsLoader(discussionID: Int(discussion.id)!, limit: limit)
        _posts = State(initialValue: Array(repeating: nil, count: discussion.attributes?.commentCount ?? 0))
    }

    private func shouldDisplayPlaceholder(index: Int) -> Bool {
        var leftBound = index
        var rightBound = index
        while leftBound >= 0 {
            if posts[leftBound] == nil {
                leftBound -= 1
            } else {
                break
            }
        }
        leftBound += 1

        while rightBound < posts.count {
            if posts[rightBound] == nil {
                rightBound += 1
            } else {
                break
            }
        }
        rightBound -= 1

        return index - leftBound + 1 <= 8
    }

    func turnOnMiniEditor() {
        miniMiniEditorDisplayed = true
        miniMiniEditorFocused = true
    }

    func turnOffMiniEditor() {
        miniMiniEditorFocused = false
        miniMiniEditorDisplayed = false
    }

    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack {
                    ForEach(0 ..< posts.count, id: \.self) { index in
                        Group {
                            if let post = posts[index] {
                                if post.isDeleted == nil {
                                    DiscussionViewPostCell(post: post, index: index)
                                        .overlay(
                                            Rectangle()
                                                .foregroundColor(.primary.opacity(0.2))
                                                .frame(height: 0.5)
                                                .offset(x: 0, y: 2),
                                            alignment: .bottom
                                        )
                                        .onAppear {
                                            checkAndLoadMoreData(index: index)
                                        }
                                } else {
                                    Color.white.opacity(0.0001).frame(height: 0.0001)
                                }
                            } else {
                                DiscussionViewPostCellPlaceholder(index: index)
                                    .overlay(
                                        Rectangle()
                                            .foregroundColor(.primary.opacity(0.2))
                                            .frame(height: 0.5)
                                            .offset(x: 0, y: 2),
                                        alignment: .bottom
                                    )
                                    .onAppear {
                                        checkAndLoadMoreData(index: index)
                                    }
                            }
                        }
                    }
                }
                .onChange(of: scrollTarget) { target in
                    if let target = target {
                        scrollTarget = nil
                        withAnimation {
                            proxy.scrollTo(target.id, anchor: target.anchor)
                        }
                    }
                }
            }
        }
        .background(Asset.DefaultTheme.defaultThemeBackground2.swiftUIColor)
        .safeAreaInset(edge: .top, content: {
            DiscussionViewHeader(discussion: discussion)
        })
        .onLoad {
            Task {
                await loadData(near: near)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                turnOnMiniEditor()
            } label: {
                Circle()
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 30, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                    )
                    .opacity(miniMiniEditorDisplayed ? 0 : 1)
            }
            .offset(x: -16, y: -16)
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .overlay(alignment: .bottom) {
            VStack {
                Color.white.opacity(0.001).offset(x: 50, y: 0)
                    .simultaneousGesture(DragGesture().onChanged { _ in turnOffMiniEditor() })
                MiniEditor(discussion: discussion, focused: _miniMiniEditorFocused, hide: turnOffMiniEditor)
            }
            .opacity(miniMiniEditorDisplayed ? 1 : 0)
        }
    }
}

extension DiscussionView {
    private func checkAndLoadMoreData(index: Int) {
        if let loadMoreState = posts[index]?.loadMoreState {
            if let prevOffset = loadMoreState.prevOffset {
                Task {
                    await loadData(offset: prevOffset)
                    posts[index]?.loadMoreState = nil
                }
            } else if let nextOffset = loadMoreState.nextOffset {
                Task {
                    await loadData(offset: nextOffset)
                    posts[index]?.loadMoreState = nil
                }
            }
        } else if posts[index] == nil {
            let pivot = max(0, near - limit / 2)
            let remain = (index - pivot) % limit
            let offset = max(0, remain > 0 ? index - remain : index - (limit + remain))
            Task {
                await loadData(offset: offset)
            }
        }
    }

    private func loadData(near: Int) async {
        let offset = max(0, near - limit / 2)
        await loadData(offset: offset)
        await loader.pause()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            scrollTarget = .init(id: near, anchor: .top)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                scrollTarget = .init(id: near, anchor: .top)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    Task {
                        await loader.resume()
                    }
                }
            }
        }
    }

    private func loadData(offset: Int) async {
        if let loadedResult = await loader.loadData(offset: offset) {
            process(offset: offset, loadedData: loadedResult.posts, loadMoreState: loadedResult.loadMoreState)
        }
    }

    private func process(offset: Int, loadedData: [FlarumPost], loadMoreState: FlarumPost.FlarumPostLoadMoreState) {
        guard loadedData.count > 0 else { return }
        // [offset, offset + loadedData.count - 1]
        if posts.count < offset + loadedData.count {
            posts.append(contentsOf: Array(repeating: nil, count: offset + loadedData.count - posts.count))
        }

        if loadedData.count < limit {
            for i in (offset + loadedData.count) ..< (offset + limit) {
                if i < posts.count, posts[i] == nil {
                    posts[i] = FlarumPost.deletedPost
                }
            }
        }

        loadedData.sorted(by: { lhs, rhs in Int(lhs.id)! < Int(rhs.id)! })
            .enumerated()
            .forEach { index, post in
                if offset + index < posts.count {
                    if posts[offset + index] == nil {
                        let threshold = 10
                        if index < threshold {
                            let _post = post
                            _post.loadMoreState = .init(prevOffset: loadMoreState.prevOffset, nextOffset: nil)
                            posts[offset + index] = _post
                        } else if index >= loadedData.count - threshold {
                            let _post = post
                            _post.loadMoreState = .init(prevOffset: nil, nextOffset: loadMoreState.nextOffset)
                            posts[offset + index] = _post
                        } else {
                            posts[offset + index] = post
                        }
                    }
                }
            }
    }
}

actor DiscussionPostsLoaderInfo {
    private var isOffsetLoading: Set<Int> = []
    private var isPaused = false
    private var loadedOffset: Set<Int> = []

    func setPaused(_ paused: Bool) {
        isPaused = paused
    }

    func shouldLoad(offset: Int) -> Bool {
        let should = !(isPaused || loadedOffset.contains(offset) || isOffsetLoading.contains(offset))
        if should {
            isOffsetLoading.insert(offset)
        }
        return should
    }

    func finishLoad(offset: Int) {
        isOffsetLoading.remove(offset)
        loadedOffset.insert(offset)
    }
}

@MainActor
private class DiscussionPostsLoader: ObservableObject {
    @Published private var discussionID: Int
    @Published private var limit: Int
    private var info = DiscussionPostsLoaderInfo()

    internal init(discussionID: Int, limit: Int) {
        self.discussionID = discussionID
        self.limit = limit
    }

    func pause() async {
        await info.setPaused(true)
    }

    func resume() async {
        await info.setPaused(false)
    }

    func loadData(offset: Int) async -> (posts: [FlarumPost], loadMoreState: FlarumPost.FlarumPostLoadMoreState)? {
        guard await info.shouldLoad(offset: offset) else { return nil }
        var postLists: [FlarumPost] = []
        var loadMoreState = FlarumPost.FlarumPostLoadMoreState()
        if let response = try? await flarumProvider.request(.posts(discussionID: discussionID,
                                                                   offset: offset,
                                                                   limit: limit)),
            let json = try? JSON(data: response.data) {
            let linksJSON = json["links"]
            let regex = Regex("page\\[offset\\]=(\\d+)")
            if let prev = linksJSON["prev"].string?.removingPercentEncoding {
                loadMoreState.prevOffset = 0
                if let offset = regex.firstMatch(in: prev)?.captures[0] {
                    loadMoreState.prevOffset = Int(offset) ?? 0
                }
            }
            if let next = linksJSON["next"].string?.removingPercentEncoding,
               let offset = regex.firstMatch(in: next)?.captures[0] {
                loadMoreState.nextOffset = Int(offset) ?? 0
            }

//             If empty, maybe we should fetch `prev`
            let posts = FlarumResponse(json: json).data.posts
            postLists.append(contentsOf: posts)
        }
        await info.finishLoad(offset: offset)
        return (posts: postLists, loadMoreState: loadMoreState)
    }
}
