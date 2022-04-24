//
//  HomeViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/22.
//

import SwiftUI
import UIKit

class HomeViewController: NoNavigationBarViewController {
    var splitVC: UISplitViewController?
    var nvc: UINavigationController?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.isNavigationBarHidden = true

        let vc = UIHostingController(rootView: HomeView()
            .environment(\.splitVC, splitViewController ?? splitVC)
            .environment(\.nvc, navigationController ?? nvc)
        )
        addChildViewController(vc, addConstrains: true)
    }
}
