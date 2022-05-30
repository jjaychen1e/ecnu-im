//
//  ReplyListViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/24.
//

import SwiftUI
import UIKit

class ReplyListViewController: UIViewController, HasNavigationPermission {
    private var hostingViewController: UIHostingController<EnvironmentWrapperView<ReplyListView>>!

    private var discussion: FlarumDiscussion
    private var originalPost: FlarumPost
    private var posts: [FlarumPost]

    init(discussion: FlarumDiscussion, originalPost: FlarumPost, posts: [FlarumPost]) {
        self.discussion = discussion
        self.originalPost = originalPost
        self.posts = posts

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingViewController = UIHostingController(rootView: EnvironmentWrapperView(
            ReplyListView(discussion: discussion, originalPost: originalPost, posts: posts),
            splitVC: splitViewController,
            nvc: navigationController,
            vc: self
        ))
        self.hostingViewController = hostingViewController
        addChildViewController(hostingViewController, addConstrains: true)
    }
}
