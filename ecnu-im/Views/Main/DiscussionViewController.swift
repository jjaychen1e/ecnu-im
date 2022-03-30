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

    init(discussion: Discussion, near: Int) {
        self.discussion = discussion
        self.near = near
        super.init(nibName: nil, bundle: nil)
        navigationController?.isNavigationBarHidden = true
    }

    override func viewWillAppear(_: Bool) {
        super.viewWillAppear(true)
        navigationController?.isNavigationBarHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    override func viewWillDisappear(_: Bool) {
        super.viewWillDisappear(true)
//        navigationController?.isNavigationBarHidden = false
//        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        navigationController?.isNavigationBarHidden = false
//        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    deinit {
        navigationController?.setNavigationBarHidden(false, animated: false)
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
        navigationController?.isNavigationBarHidden = true
        // When embedded in UISplitViewController, this may fail...
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.navigationController?.isNavigationBarHidden = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.navigationController?.isNavigationBarHidden = true
        }
    }
}
