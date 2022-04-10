//
//  DiscussionViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/4.
//

import SwiftUI
import UIKit

class DiscussionViewController: UIViewController {
    private var discussion: Discussion
    private var near: Int

    private weak var navigationBarTimer: Timer!

    init(discussion: Discussion, near: Int) {
        self.discussion = discussion
        self.near = near
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationBarTimer.invalidate()
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
        addSubViewController(discussionViewHostingController, addConstrains: true)

        // UISplitViewController will show UINavigationBar in many cases. It will be displayed
        // even we hide it in `viewDidLoad`. And when present another VC, it will be displayed, too.
        navigationBarTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            self.navigationController?.isNavigationBarHidden = true
        }
    }
}
