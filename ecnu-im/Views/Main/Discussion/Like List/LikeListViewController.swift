//
//  LikeListViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/24.
//

import SwiftUI
import UIKit

class LikeListViewController: UIViewController {
    private var hostingViewController: UIHostingController<EnvironmentWrapperView<LikeListView>>!

    private var users: [FlarumUser]

    init(users: [FlarumUser]) {
        self.users = users

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingViewController = UIHostingController(rootView: EnvironmentWrapperView(
            LikeListView(users: users),
            splitVC: splitViewController,
            nvc: navigationController,
            vc: self
        ))
        self.hostingViewController = hostingViewController
        addChildViewController(hostingViewController, addConstrains: true)
    }
}
