//
//  DiscussionViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/4.
//

import SwiftUI
import UIKit

class DiscussionViewController: NoNavigationBarViewController {
    private var discussion: FlarumDiscussion
    private var near: Int

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
        let discussionViewHostingController = UIHostingController(rootView:
            DiscussionView(discussion: discussion, near: near)
                .environment(\.splitVC, splitViewController)
                .environment(\.nvc, navigationController)
        )
        addChildViewController(discussionViewHostingController, addConstrains: true)
    }
}
