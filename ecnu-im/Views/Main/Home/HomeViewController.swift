//
//  HomeViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/22.
//

import SwiftUI
import UIKit

class HomeViewController: NoNavigationBarViewController {
    weak var splitVC: UISplitViewController?
    weak var nvc: UINavigationController?

    override func viewDidLoad() {
        super.viewDidLoad()

        let vc = UIHostingController(rootView: HomeView()
            .environment(\.splitVC, splitViewController ?? splitVC)
            .environment(\.nvc, navigationController ?? nvc)
            .environment(\.viewController, self)
        )
        addChildViewController(vc, addConstrains: true)
    }
}
