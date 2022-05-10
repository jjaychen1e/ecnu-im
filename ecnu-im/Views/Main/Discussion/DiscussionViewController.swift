//
//  DiscussionViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/4.
//

import Regex
import SnapKit
import SwiftSoup
import SwiftUI
import SwiftyJSON
import UIKit

private enum Post: Hashable {
    case comment(FlarumPost)
    case deleted(Int)
    case placeholder(Int)
}

class DiscussionViewController: NoNavigationBarViewController, UITableViewDelegate, UITableViewDataSource {
    static let margin = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    
    private var discussion: FlarumDiscussion
    private var near: Int
    private var loader: DiscussionPostsLoader

    private enum LoadMoreState {
        case finished
        case placeholder
        case normal(prev: Int?, next: Int?)
    }

    private var initialized = false
    private var loadMoreStates: [LoadMoreState] = []
    private var posts: [Post] = []
    private let limit = 30

    private var tableView: UITableView!

    var initialPostsCount: Int {
        let commentCount = discussion.attributes?.commentCount ?? 0
        let lastPostNumber = discussion.lastPost?.attributes?.number ?? 0
        return max(commentCount, lastPostNumber)
    }

    init(discussion: FlarumDiscussion, near: Int) {
        self.discussion = discussion
        self.near = near
        loader = DiscussionPostsLoader(discussionID: Int(discussion.id)!, limit: limit)
        super.init(nibName: nil, bundle: nil)
        loadMoreStates = .init(repeating: .placeholder, count: initialPostsCount)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            setTableView()
            await loadData(near: near)
        }
    }

    private func setTableView() {
        // UI - Header
        let headerVC = DiscussionHeaderViewController(discussion: discussion)
        headerVC.splitVC = splitViewController
        headerVC.nvc = navigationController
        addChildViewController(headerVC)
        headerVC.view.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        // UI - UICollectionView
        let tableView = UITableView(frame: .zero)
        self.tableView = tableView
        tableView.separatorInset = .zero
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = 40
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(headerVC.view.snp.bottom)
        }

        // Data Source
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PostCommentCell.self, forCellReuseIdentifier: PostCommentCell.identifier)
        tableView.register(PostPlaceholderCell.self, forCellReuseIdentifier: PostPlaceholderCell.identifier)
        tableView.register(PostDeletedCell.self, forCellReuseIdentifier: PostDeletedCell.identifier)
        posts = (0 ..< initialPostsCount).map { .placeholder($0) }
        tableView.reloadData()
    }

    private func convertFlarumPostToPost(flarumPost: FlarumPost, index: Int) -> Post {
        if let contentType = flarumPost.attributes?.contentType {
            switch contentType {
            case .comment:
                return .comment(flarumPost)
            case .discussionRenamed:
                return .deleted(index)
            case .discussionTagged:
                return .deleted(index)
            case .discussionLocked:
                return .deleted(index)
            }
        }
        return .deleted(index)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.row]
        switch post {
        case let .comment(post):
            let cell = tableView.dequeueReusableCell(withIdentifier: PostCommentCell.identifier, for: indexPath) as! PostCommentCell
            cell.configure(post: post) {
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        tableView.reconfigureRows(at: [indexPath])
                    }
                }
            }
            return cell
        case .deleted:
            let cell = tableView.dequeueReusableCell(withIdentifier: PostDeletedCell.identifier, for: indexPath) as! PostDeletedCell
            cell.configure()
            return cell
        case .placeholder:
            let cell = tableView.dequeueReusableCell(withIdentifier: PostPlaceholderCell.identifier, for: indexPath) as! PostPlaceholderCell
            cell.configure()
            return cell
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if initialized {
            checkAndLoadMoreData(index: indexPath.row)
        }
    }
}

extension DiscussionViewController {
    private func checkAndLoadMoreData(index: Int) {
        let loadMoreState = loadMoreStates[index]

        switch loadMoreState {
        case let .normal(prev: prev, next: next):
            if let prevOffset = prev {
                Task {
                    await loadData(offset: prevOffset)
                    loadMoreStates[index] = .finished
                }
            } else if let nextOffset = next {
                Task {
                    await loadData(offset: nextOffset)
                    loadMoreStates[index] = .finished
                }
            }
        case .placeholder:
            let pivot = max(0, near - limit / 2)
            let remain = (index - pivot) % limit
            let offset = max(0, remain > 0 ? index - remain : index - (limit + remain))
            Task {
                await loadData(offset: offset)
                loadMoreStates[index] = .finished
            }
        case .finished:
            break
        }
    }

    /// Called when first time initialized
    /// - Parameter near: target post number id
    private func loadData(near: Int) async {
        let offset = max(0, near - limit / 2)
        await loadData(offset: offset, completionHandler: { [weak self] in
            self?.tableView.scrollToRow(at: IndexPath(row: near, section: 0), at: .top, animated: false)
        })
        initialized = true
    }

    private func loadData(offset: Int, completionHandler: (() -> Void)? = nil) async {
        if let loadedResult = await loader.loadData(offset: offset) {
            process(offset: offset, loadedData: loadedResult.posts, loadMoreState: loadedResult.loadMoreState, completionHandler: completionHandler)
        }
    }

    private func process(offset: Int, loadedData: [FlarumPost], loadMoreState: FlarumPost.FlarumPostLoadMoreState, completionHandler: (() -> Void)? = nil) {
        guard loadedData.count > 0 else { return }
        // [offset, offset + loadedData.count - 1]
        var posts = posts

        // If the array if too short(may be new posts are sent)
        if offset + loadedData.count > posts.count {
            let diffRange = posts.count ..< (offset + loadedData.count)
            for index in diffRange {
                posts.append(.placeholder(index))
                loadMoreStates.append(.placeholder)
            }
        }

        // Set all posts to `deleted`, and post actual value later.
        for i in offset ..< min(posts.count, offset + limit) {
            if case .comment = posts[i] {
                continue
            }
            posts[i] = .deleted(i)
        }

        loadedData.sorted(by: { lhs, rhs in Int(lhs.id)! < Int(rhs.id)! })
            .enumerated()
            .forEach { indexInArray, post in
                if let number = post.attributes?.number {
                    let actualIndex = number - 1
                    if actualIndex < posts.count {
                        if case .comment = posts[actualIndex] {
                            return
                        }
                        let isTopHalf = indexInArray < loadedData.count / 2
                        if isTopHalf {
                            loadMoreStates[actualIndex] = .normal(prev: loadMoreState.prevOffset, next: nil)
                            posts[actualIndex] = convertFlarumPostToPost(flarumPost: post, index: actualIndex)
                        } else {
                            loadMoreStates[actualIndex] = .normal(prev: nil, next: loadMoreState.nextOffset)
                            posts[actualIndex] = convertFlarumPostToPost(flarumPost: post, index: actualIndex)
                        }
                    }
                }
            }

        let modified = (offset ..< min(posts.count, offset + limit)).map {
            IndexPath(row: $0, section: 0)
        }
        if posts.count > self.posts.count {
            UIView.performWithoutAnimation {
                tableView.performBatchUpdates {
                    tableView.insertRows(at: (self.posts.count ..< posts.count).map { IndexPath(row: $0, section: 0) }, with: .none)
                    tableView.reloadRows(at: modified, with: .none)
                    self.posts = posts
                } completion: { completed in
                    completionHandler?()
                }
            }
        } else {
            UIView.performWithoutAnimation {
                tableView.performBatchUpdates {
                    tableView.reloadRows(at: modified, with: .none)
                    self.posts = posts
                } completion: { completed in
                    completionHandler?()
                }
            }
        }
    }
}

@MainActor
private class DiscussionPostsLoader: ObservableObject {
    actor DiscussionPostsLoaderInfo {
        private var isOffsetLoading: Set<Int> = []
        private var isPaused = false
        private var loadedOffset: Set<Int> = []

        func setPaused(_ paused: Bool) {
            isPaused = paused
        }

        func shouldLoad(offset: Int) -> Bool {
            let should = !(isPaused || loadedOffset.contains(offset) || isOffsetLoading.contains(offset) || isOffsetLoading.count > 0)
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
        print("loading: \(offset)")
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
        print("finish loading: \(offset)")
        return (posts: postLists, loadMoreState: loadMoreState)
    }
}
