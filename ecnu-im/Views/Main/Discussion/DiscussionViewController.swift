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

class DiscussionViewController: NoNavigationBarViewController, NoOverlayViewController, UITableViewDelegate, UITableViewDataSource {
    static let margin = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    static let backgroundColor = UIColor(dynamicProvider: { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor("#1C1C1E")
        }
        return .white
    })

    private var discussion: FlarumDiscussion

    private enum InitState {
        case nearOffset(Int)
        case nearNumber(Int)
    }

    private var initState: InitState

    private var loader: DiscussionPostsLoader

    private enum LoadMoreState {
        case finished
        case placeholder
        case normal(prev: Int?, next: Int?)
    }

    private var initialized = false
    private var loadMoreStates: [LoadMoreState] = []
    private var posts: [Post] = []
    private var numberRangeRecordMap: [Int: (Int, Int)] = [:] // offset : (minIndex, maxIndex)
    private let limit = 30

    private var tableView: UITableView!

    var initialPostsCount: Int {
        let commentCount = discussion.attributes?.commentCount ?? 0
        let lastPostNumber = discussion.lastPost?.attributes?.number ?? 0
        return max(commentCount, lastPostNumber)
    }

    init(discussion: FlarumDiscussion, nearOffset: Int) {
        self.discussion = discussion
        initState = .nearOffset(nearOffset)
        loader = DiscussionPostsLoader(discussionID: Int(discussion.id)!, limit: limit)
        super.init(nibName: nil, bundle: nil)
        loadMoreStates = .init(repeating: .placeholder, count: initialPostsCount)
    }

    init(discussion: FlarumDiscussion, nearNumber: Int) {
        self.discussion = discussion
        initState = .nearNumber(nearNumber)
        loader = DiscussionPostsLoader(discussionID: Int(discussion.id)!, limit: limit)
        super.init(nibName: nil, bundle: nil)
        loadMoreStates = .init(repeating: .placeholder, count: initialPostsCount)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func shouldPushTo(nvc: UINavigationController?) -> Bool {
        if let top = nvc?.topViewController,
           let another = top as? DiscussionViewController {
            return discussion != another.discussion
        }
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            setTableView()
            await loadData(initState: initState)
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
        tableView.backgroundColor = Self.backgroundColor
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
                    await loadData(offset: prevOffset, completionHandler: {})
                    loadMoreStates[index] = .finished
                }
            } else if let nextOffset = next {
                Task {
                    await loadData(offset: nextOffset, completionHandler: {})
                    loadMoreStates[index] = .finished
                }
            }
        case .placeholder:
            var targetNeat: Int
            switch initState {
            case let .nearOffset(nearOffset):
                targetNeat = nearOffset
            case let .nearNumber(nearNumber):
                targetNeat = nearNumber
            }

            // This is inaccurate, since we don't know nearNumber's corresponding offset
            let pivot = max(0, targetNeat - limit / 2)
            let remain = (index - pivot) % limit
            let offset = max(0, remain > 0 ? index - remain : index - (limit + remain))
            Task {
                await loadData(offset: offset, completionHandler: {})
                loadMoreStates[index] = .finished
            }
        case .finished:
            break
        }
    }

    /// Only called when first time initialized
    private func loadData(initState: InitState) async {
        switch initState {
        case let .nearOffset(nearOffset):
            let offset = max(0, nearOffset - limit / 2)
            await loadData(offset: offset, completionHandler: { [weak self] in
                if let self = self {
                    if offset < self.posts.count {
                        self.tableView.scrollToRow(at: IndexPath(row: offset, section: 0), at: .top, animated: false)
                    } else {
                        #if DEBUG
                            fatalError("Scroll target out of index!!")
                        #endif
                    }
                }
            })
        case let .nearNumber(nearNumber):
            await loadData(nearNumber: nearNumber, completionHandler: { [weak self] in
                if let self = self {
                    // Find out the closet comment(it could be a re-name, re-rag, actually.
                    if let closest = self.posts.min(by: { p1, p2 in
                        if case let .comment(comment1) = p1, case let .comment(comment2) = p2 {
                            if let number1 = comment1.attributes?.number, let number2 = comment2.attributes?.number {
                                return abs(nearNumber - number1) < abs(nearNumber - number2)
                            }
                            #if DEBUG
                                fatalError("number is nil...")
                            #else
                                return false
                            #endif
                        } else if case .comment = p1 {
                            return true
                        } else if case .comment = p2 {
                            return false
                        } else {
                            return false
                        }
                    }) {
                        if let index = self.posts.firstIndex(of: closest) {
                            self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: false)
                        }
                    } else {
                        #if DEBUG
                            fatalError("Can not find nearNumber's row!!")
                        #endif
                    }
                }
            })
        }
        initialized = true
    }

    private func loadData(offset: Int, completionHandler: @escaping () -> Void) async {
        if let loadedResult = await loader.loadData(offset: offset) {
            process(offset: offset, loadedData: loadedResult.posts, loadMoreState: loadedResult.loadMoreState, completionHandler: completionHandler)
        }
    }

    private func loadData(nearNumber: Int, completionHandler: @escaping () -> Void) async {
        let loadedResult = await loader.loadData(nearNumber: nearNumber)
        if loadedResult.count > 0 {
            process(nearNumber: nearNumber, loadedData: loadedResult, completionHandler: completionHandler)
        } else {
            #if DEBUG
                fatalError("First init return empty data!")
            #endif
        }
    }

    private func process(offset: Int? = nil, nearNumber: Int? = nil, loadedData: [FlarumPost], loadMoreState: FlarumPost.FlarumPostLoadMoreState? = nil, completionHandler: @escaping () -> Void) {
        guard loadedData.count > 0 else { return }
        // [offset, offset + loadedData.count - 1]
        var posts = posts

        let comparator: (FlarumPost, FlarumPost) -> Bool = {
            if let number1 = $0.attributes?.number, let number2 = $1.attributes?.number {
                return number1 < number2
            }
            return false
        }

        if let maxPostNumber = loadedData.max(by: comparator)?.attributes?.number,
           let minPostNumber = loadedData.min(by: comparator)?.attributes?.number {
            #if DEBUG
                assert(minPostNumber - 1 >= 0)
                assert(maxPostNumber - 1 >= 0)
            #endif

            let minIndex = max(0, minPostNumber - 1)
            let maxIndex = max(0, maxPostNumber - 1)
            if let offset = offset {
                numberRangeRecordMap[offset] = (minIndex, maxIndex)
            }

            // If the array if too short(may be new posts are sent)
            if maxPostNumber > posts.count {
                let diffRange = posts.count ..< maxPostNumber
                for index in diffRange {
                    posts.append(.placeholder(index))
                    loadMoreStates.append(.placeholder)
                }
            }

            // Set all posts to `deleted`, and put actual value later.
            // And considering the last and next section
            var rangeLeft = minIndex
            var rangeRight = maxIndex
            if let offset = offset {
                if let lastSectionRange = numberRangeRecordMap[max(0, offset - limit)] {
                    rangeLeft = min(rangeLeft, lastSectionRange.1 + 1)
                }
                if let nextSectionRange = numberRangeRecordMap[offset + limit] {
                    rangeRight = max(rangeRight, nextSectionRange.0 - 1)
                }
            }

            var modified: [IndexPath] = []
            let range = rangeLeft ... rangeRight
            for i in range {
                if case .comment = posts[i] {
                    // This could actually happen, because we rely on prev & next from API, and
                    // First time fetch may rely on nearNumber, in that case we don't know the
                    //  actual offset is, so consequent fetching may overlay with first fetch.
                    continue
                }
                posts[i] = .deleted(i)
                modified.append(.init(row: i, section: 0))
                let isTopHalf = i - rangeLeft < range.count / 2
                if let loadMoreState = loadMoreState {
                    if isTopHalf {
                        loadMoreStates[i] = .normal(prev: loadMoreState.prevOffset, next: nil)
                    } else {
                        loadMoreStates[i] = .normal(prev: nil, next: loadMoreState.nextOffset)
                    }
                } else if let nearNumber = nearNumber {
                    if isTopHalf {
                        loadMoreStates[i] = .normal(prev: max(0, nearNumber - limit), next: nil)
                    } else {
                        loadMoreStates[i] = .normal(prev: nil, next: nearNumber + limit)
                    }
                } else {
                    #if DEBUG
                        fatalError("This should never happen.")
                    #endif
                }
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
                            posts[actualIndex] = convertFlarumPostToPost(flarumPost: post, index: actualIndex)
                        } else {
                            #if DEBUG
                                fatalError("Out of index!!")
                            #endif
                        }
                    }
                }

            if posts.count > self.posts.count {
                UIView.performWithoutAnimation {
                    tableView.performBatchUpdates {
                        tableView.insertRows(at: (self.posts.count ..< posts.count).map { IndexPath(row: $0, section: 0) }, with: .none)
                        tableView.reloadRows(at: modified, with: .none)
                        self.posts = posts
                    } completion: { completed in
                        completionHandler()
                    }
                }
            } else {
                UIView.performWithoutAnimation {
                    tableView.performBatchUpdates {
                        tableView.reloadRows(at: modified, with: .none)
                        self.posts = posts
                    } completion: { completed in
                        completionHandler()
                    }
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
                                                                   limit: limit)) {
            let json = JSON(response.data)
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

    func loadData(nearNumber: Int) async -> [FlarumPost] {
        print("loading near number: \(nearNumber)")
        var postLists: [FlarumPost] = []
        if let response = try? await flarumProvider.request(.postsNearNumber(discussionID: discussionID,
                                                                             nearNumber: nearNumber,
                                                                             limit: limit)) {
            let json = JSON(response.data)
            let posts = FlarumResponse(json: json).data.posts
            postLists.append(contentsOf: posts)
        }
        print("finish loading near number: \(nearNumber)")
        return postLists
    }
}
