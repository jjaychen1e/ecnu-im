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
    @State private var post: Post
    @State private var index: Int

    init(post: Post, index: Int) {
        _post = State(wrappedValue: post)
        _index = State(wrappedValue: index)
    }

    var body: some View {
        VStack {
            HStack {
                PostAuthorAvatarView(name: post.authorName, url: post.authorAvatarURL, size: 40)
                VStack(alignment: .leading) {
                    HStack {
                        Text(post.authorName)
                            .font(.system(size: 12, weight: .medium))
                        Text(post.createdDateDescription)
                            .font(.system(size: 10, weight: .light))
                        Text("#\(post.attributes!.number)")
                    }
                }
                Spacer()
            }
            parseConvertedHTMLViewComponents(views: post.postContentViews,
                                             configuration: .init(imageOnTapAction: { ImageBrowser.shared.present(imageURLs: $1, selectedImageIndex: $0) },
                                                                  imageGridDisplayMode: horizontalSizeClass == .compact ? .narrow : .wide))
        }
        .padding(.horizontal, 16)
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

private struct DiscussionHeaderTagView: View {
    @EnvironmentObject var tagsViewModel: TagsViewModel

    private let tag: TagViewModel

    init(tag: TagViewModel) {
        self.tag = tag
    }

    var body: some View {
        HStack(spacing: 2) {
            HStack(spacing: 2) {
                if let iconInfo = tag.iconInfo {
                    Text(fa: iconInfo.icon, faStyle: iconInfo.style, size: 14)
                }
                Text(tag.name)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background(Asset.dynamicWhite.swiftUIColor)
            .cornerRadius(4)

            if let childTag = tag.child {
                Text(childTag.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Asset.dynamicWhite.swiftUIColor)
            }
        }
        .foregroundColor(tag.backgroundColor)
    }
}

private struct DiscussionViewHeader: View {
    @Environment(\.splitVC) var splitVC
    @Environment(\.nvc) var nvc
    @State private var discussion: Discussion

    init(discussion: Discussion) {
        _discussion = State(initialValue: discussion)
    }

    var body: some View {
        VStack {
            Group {
                if discussion.synthesisedTag != nil {
                    DiscussionHeaderTagView(tag: discussion.synthesisedTag!)
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
        .foregroundColor(Asset.dynamicWhite.swiftUIColor)
        .background(discussion.synthesisedTag?.backgroundColor ?? .gray)
        .overlay(
            Group {
                if let splitVC = splitVC {
                    if splitVC.traitCollection.horizontalSizeClass == .compact {
                        Button(action: {
                            if let nvc = nvc {
                                if nvc.viewControllers.count == 1 {
                                    splitVC.show(.supplementary)
                                } else {
                                    nvc.popViewController(animated: true)
                                }
                            }
                        }, label: {
                            Image(systemName: "arrow.backward.circle.fill")
                                .font(.system(size: 30, weight: .medium))
                                .foregroundColor(Asset.dynamicWhite.swiftUIColor)
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
    @State private var posts: [Post?] = []
    @State private var scrollTarget: ScrollTarget?
    @State private var discussion: Discussion
    @State private var near: Int
    @StateObject private var dumbPublisher = DumbPublisher()
    @State private var loader: DiscussionPostsLoader

    private let limit = 30

    var discussionID: Int {
        Int(discussion.id)!
    }

    init(discussion: Discussion, near: Int) {
        _discussion = State(initialValue: discussion)
        _near = State(initialValue: near)
        _loader = State(initialValue: DiscussionPostsLoader(discussionID: Int(discussion.id)!, limit: limit))
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
        .onReceive(dumbPublisher.$publishedValue) { output in
            if output == 0 {
                loader = .init(discussionID: discussionID, limit: limit)
            }
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

    private func process(offset: Int, loadedData: [Post], loadMoreState: LoadMoreState) {
        guard loadedData.count > 0 else { return }
        // [offset, offset + loadedData.count - 1]
        if posts.count < offset + loadedData.count {
            posts.append(contentsOf: Array(repeating: nil, count: offset + loadedData.count - posts.count))
        }

        if loadedData.count < limit {
            for i in (offset + loadedData.count) ..< (offset + limit) {
                if i < posts.count, posts[i] == nil {
                    posts[i] = .init(id: "0", isDeleted: true)
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
                            var _post = post
                            _post.loadMoreState = .init(prevOffset: loadMoreState.prevOffset, nextOffset: nil)
                            posts[offset + index] = _post
                        } else if index >= loadedData.count - threshold {
                            var _post = post
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

private class DiscussionPostsLoader {
    var discussionID: Int
    private var limit: Int
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

    func loadData(offset: Int) async -> (posts: [Post], loadMoreState: LoadMoreState)? {
        guard await info.shouldLoad(offset: offset) else { return nil }
        var postLists: [Post] = []
        var loadMoreState = LoadMoreState()
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

            let includedData = DataParser.parseIncludedData(json: json["included"])
            let includedUsers = includedData.includedUsers
            let includedPosts = includedData.includedPosts

            if let postListJSON = json["data"].array {
                if postListJSON.count == 0 {
                    // Maybe.. prev
//                    return await loadData()
                }
                for postJSON in postListJSON {
                    let relationshipsJSON = postJSON["relationships"]
                    let postJSONWithoutRelationships = postJSON.removing(key: "relationships")
                    if let postData = try? postJSONWithoutRelationships.rawData(),
                       var post = try? JSONDecoder().decode(Post.self, from: postData) {
                        if let user = relationshipsJSON["user"]["data"]["id"].string,
                           let discussion = relationshipsJSON["discussion"]["data"]["id"].string {
                            let likes = relationshipsJSON["likes"]["data"].arrayValue.map { $0["id"].string }.compactMap { $0 }
                            let mentionedBy = relationshipsJSON["mentionedBy"]["data"].arrayValue.map { $0["id"].string }.compactMap { $0 }
                            let reactions = relationshipsJSON["reactions"]["data"].arrayValue.map { $0["id"].string }.compactMap { $0 }
                            let postRelationship = PostRelationship(user: user,
                                                                    discussion: discussion,
                                                                    likes: likes,
                                                                    reactions: reactions,
                                                                    mentionedBy: mentionedBy)
                            post.includedUsers.append(contentsOf: includedUsers.filter { $0.id == user })
                            post.includedPosts.append(contentsOf: includedPosts.filter { mentionedBy.contains($0.id) })
                            post.relationships = postRelationship
                            postLists.append(post)
                        }
                    }
                }
            }
        }
        await info.finishLoad(offset: offset)
        return (posts: postLists, loadMoreState: loadMoreState)
    }
}
