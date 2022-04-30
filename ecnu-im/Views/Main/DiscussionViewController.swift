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
}

private typealias DataSource = UICollectionViewDiffableDataSource<Section, Post>

class DiscussionViewController: NoNavigationBarViewController {
    private var discussion: FlarumDiscussion
    private var near: Int

    private var postList: [FlarumPost] = []

    private var collectionView: UICollectionView!
    private lazy var dataSource: DataSource = makeDataSource()

    init(discussion: FlarumDiscussion, near: Int) {
        self.discussion = discussion
        self.near = near
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setCollectionView()
        loadData()
    }

    private func setCollectionView() {
        // UI
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
        self.collectionView = collectionView
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Data Source
        var dataSourceSnapshot = NSDiffableDataSourceSnapshot<Section, Post>()
        dataSourceSnapshot.appendSections([.main])
        dataSource.apply(dataSourceSnapshot)
    }

    private func makeDataSource() -> DataSource {
        let postCommentCellRegistration = UICollectionView.CellRegistration<PostCommentCell, Post> {
            cell, indexPath, item in
            if case let .comment(post) = item {
                cell.post = post
            }
        }

        return DataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            var cell: UICollectionViewCell?
            switch item {
            case .comment:
                cell = collectionView.dequeueConfiguredReusableCell(using: postCommentCellRegistration, for: indexPath, item: item)
            }
            return cell
        }
    }

    func loadData() {
        Task {
            if let response = try? await flarumProvider.request(.posts(discussionID: Int(discussion.id)!,
                                                                       offset: 0,
                                                                       limit: 20)) {
                if let json = try? JSON(data: response.data) {
                    // If empty, maybe we should fetch prev
                    let posts = FlarumResponse(json: json).data.posts
                    postList.append(contentsOf: posts)

                    // Data Source
                    var snapshot = NSDiffableDataSourceSectionSnapshot<Post>()
                    snapshot.append(posts.map { .comment($0) })
                    await dataSource.apply(snapshot, to: .main, animatingDifferences: true)
                }
            }
        }
    }
}

final class PostCommentCell: UICollectionViewCell {
    var post: FlarumPost? {
        didSet {
            setNeedsUpdateConfiguration()
        }
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        var newConfiguration = PostCommentCellConfiguration().updated(for: state)
        newConfiguration.post = post
        contentConfiguration = newConfiguration
    }
}

struct PostCommentCellConfiguration: UIContentConfiguration, Hashable {
    var post: FlarumPost?

    func makeContentView() -> UIView & UIContentView {
        PostCommentCellContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> PostCommentCellConfiguration {
        guard state is UICellConfigurationState else {
            return self
        }

        return self
    }
}

class PostCommentCellContentView: UIView, UIContentView {
    private lazy var authorLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    private lazy var idNumber: UILabel = {
        let label = UILabel()
        return label
    }()

    private var idNumberBottomConstraint: Constraint!

    private var postContentItemsUIView: PostContentItemsUIView?

    private var currentConfiguration: PostCommentCellConfiguration!
    var configuration: UIContentConfiguration {
        get { currentConfiguration }
        set {
            guard let newConfiguration = newValue as? PostCommentCellConfiguration else { return }
            apply(configuration: newConfiguration)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(configuration: PostCommentCellConfiguration) {
        super.init(frame: .zero)
        setViewHierarchy()
        apply(configuration: configuration)
    }

    private func setViewHierarchy() {
        addSubview(authorLabel)
        authorLabel.text = "@unknown"
        authorLabel.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
        }

        addSubview(idNumber)
        idNumber.text = "unknown id"
        idNumber.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(authorLabel.snp.bottom)
            idNumberBottomConstraint = make.bottom.equalToSuperview().constraint
        }
    }

    func apply(configuration: PostCommentCellConfiguration) {
        guard currentConfiguration != configuration else { return }
        currentConfiguration = configuration

        postContentItemsUIView?.removeFromSuperview()

        if let post = configuration.post, let content = post.attributes?.content, case let .comment(comment) = content {
            authorLabel.text = post.authorName
            if let id = post.attributes?.number {
                idNumber.text = "\(id)"
            } else {
                idNumber.text = "unknown parsed id"
            }

            let parseConfiguration = ParseConfiguration(imageOnTapAction: { ImageBrowser.shared.present(imageURLs: $1, selectedImageIndex: $0) },
                                                        imageGridDisplayMode: .narrow)
            let contentParser = ContentParser(content: comment, configuration: parseConfiguration)
            let newContentItems = contentParser.parse()
            if newContentItems.count > 0 {
                idNumberBottomConstraint.deactivate()
                let postContentItemsUIView = PostContentItemsUIView(contentItems: newContentItems)
                self.postContentItemsUIView = postContentItemsUIView
                addSubview(postContentItemsUIView)
                postContentItemsUIView.snp.makeConstraints { make in
                    make.leading.bottom.trailing.equalToSuperview()
                    make.top.equalTo(idNumber.snp.bottom)
                }
            } else {
                idNumberBottomConstraint.activate()
            }
        } else {
            authorLabel.text = "Update failed"
            idNumber.text = "Update failed"
            idNumberBottomConstraint.activate()
        }
    }
}
