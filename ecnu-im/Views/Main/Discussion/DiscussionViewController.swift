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

private enum Section: Hashable {
    case main
}

private enum Post: Hashable {
    case comment(FlarumPost)
    case deleted(Int)
    case placeholder(Int)
}

private typealias DataSource = UICollectionViewDiffableDataSource<Section, Post>

class DiscussionViewController: NoNavigationBarViewController, UICollectionViewDelegate {
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
    private let limit = 30

    private var collectionView: UICollectionView!
    private lazy var dataSource: DataSource = makeDataSource()

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
            setCollectionView()
            await loadData(near: near)
        }
    }

    private func setCollectionView() {
        // UI - Header
        let headerVC = DiscussionHeaderViewController(discussion: discussion)
        addChildViewController(headerVC)
        headerVC.view.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        // UI - UICollectionView
        let size = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
            heightDimension: NSCollectionLayoutDimension.estimated(120)
        )
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        section.interGroupSpacing = 0

        let layout = UICollectionViewCompositionalLayout(section: section)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        self.collectionView = collectionView
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(headerVC.view.snp.bottom)
        }

        // Data Source
        var dataSourceSnapshot = NSDiffableDataSourceSnapshot<Section, Post>()
        dataSourceSnapshot.appendSections([.main])
        dataSourceSnapshot.appendItems((0 ..< initialPostsCount).map { .placeholder($0) }, toSection: .main)
        dataSource.apply(dataSourceSnapshot)
    }

    private func makeDataSource() -> DataSource {
        let postCommentCellRegistration = UICollectionView.CellRegistration<PostCommentCell, Post> {
            cell, indexPath, item in
            if case let .comment(post) = item {
                cell.post = post
            }
        }

        let postPlaceholderCellRegistration = UICollectionView.CellRegistration<PostPlaceholderCell, Post> {
            cell, indexPath, item in
            // Nothing to do..
        }

        let postDeletedCellRegistration = UICollectionView.CellRegistration<PostDeletedCell, Post> {
            cell, indexPath, item in
            return
        }

        return DataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            if self.initialized {
                self.checkAndLoadMoreData(index: indexPath.row)
            }

            var cell: UICollectionViewCell?
            switch item {
            case .comment:
                cell = collectionView.dequeueConfiguredReusableCell(using: postCommentCellRegistration, for: indexPath, item: item)
            case .deleted:
                cell = collectionView.dequeueConfiguredReusableCell(using: postDeletedCellRegistration, for: indexPath, item: item)
            case .placeholder:
                cell = collectionView.dequeueConfiguredReusableCell(using: postPlaceholderCellRegistration, for: indexPath, item: item)
            }
            return cell
        }
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

//    private func loadData() {
//        Task {
//            if let response = try? await flarumProvider.request(.posts(discussionID: Int(discussion.id)!,
//                                                                       offset: 0,
//                                                                       limit: limit)) {
//                if let json = try? JSON(data: response.data) {
//                    // If empty, maybe we should fetch prev
//                    let posts = FlarumResponse(json: json).data.posts
//
//                    // Update data source based on current data source
//                    var snapshot = dataSource.snapshot(for: .main)
//                    snapshot.append(posts.map {
//                        convertFlarumPostToPost(flarumPost: $0,
//                                                index: $0.attributes?.number ?? Int.random(in: Int.min ..< Int.max))
//                    })
//                    await dataSource.apply(snapshot, to: .main, animatingDifferences: true)
//                }
//            }
//        }
//    }
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
        await loadData(offset: offset)
        initialized = true
        collectionView.scrollToItem(at: .init(row: near - 1, section: 0), at: .centeredVertically, animated: false)
    }

    private func loadData(offset: Int) async {
        if let loadedResult = await loader.loadData(offset: offset) {
            process(offset: offset, loadedData: loadedResult.posts, loadMoreState: loadedResult.loadMoreState)
        }
    }

    private func process(offset: Int, loadedData: [FlarumPost], loadMoreState: FlarumPost.FlarumPostLoadMoreState) {
        guard loadedData.count > 0 else { return }
        // [offset, offset + loadedData.count - 1]
        var snapshot = dataSource.snapshot(for: .main)
        var posts = snapshot.items

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

        snapshot.deleteAll()
        snapshot.append(posts)
        dataSource.apply(snapshot, to: .main, animatingDifferences: true)
    }
}
