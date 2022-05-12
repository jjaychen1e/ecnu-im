//
//  NotificationCenterViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/11.
//

import SwiftUI
import UIKit

class NotificationCenterViewController: NoNavigationBarViewController {
    weak var splitVC: UISplitViewController?
    weak var nvc: UINavigationController?

    override func viewDidLoad() {
        super.viewDidLoad()

        let vc = UIHostingController(rootView: NotificationCenterView()
            .environment(\.splitVC, splitViewController ?? splitVC)
            .environment(\.nvc, navigationController ?? nvc)
            .environment(\.viewController, self)
        )
        addChildViewController(vc, addConstrains: true)
    }
}
