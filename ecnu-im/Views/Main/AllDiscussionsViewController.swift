//
//  AllDiscussionsViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/3.
//

import SwiftUI
import UIKit

class AllDiscussionsViewController: UIViewController {
    private var hostingViewController: Any!

    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingViewController = UIHostingController(rootView:
            AllDiscussionsView()
                .environment(\.splitVC, splitViewController)
                .environment(\.nvc, navigationController)
        )
        self.hostingViewController = hostingViewController
        addSubViewController(hostingViewController, addConstrains: true)
        title = "最新回复"
        let scrollEdgeAppearance = UINavigationBarAppearance()
        navigationItem.scrollEdgeAppearance = scrollEdgeAppearance
    }
}
