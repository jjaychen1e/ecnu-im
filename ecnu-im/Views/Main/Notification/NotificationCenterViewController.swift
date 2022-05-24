//
//  NotificationCenterViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/11.
//

import SwiftUI
import UIKit

class NotificationCenterViewController: UIViewController, HasNavigationPermission {
    weak var splitVC: UISplitViewController?
    weak var nvc: UINavigationController?

    private var hostingVC: UIHostingController<EnvironmentWrapperView<NotificationCenterView>>!

    override func viewDidLoad() {
        super.viewDidLoad()
        let vc = UIHostingController(rootView: EnvironmentWrapperView(
            NotificationCenterView(),
            splitVC: splitViewController ?? splitVC,
            nvc: navigationController ?? nvc,
            vc: self
        ))
        hostingVC = vc
        addChildViewController(vc, addConstrains: true)
    }
}
