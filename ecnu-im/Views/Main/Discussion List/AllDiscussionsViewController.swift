//
//  AllDiscussionsViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/3.
//

import ReCaptcha
import RxSwift
import SwiftUI
import UIKit

class AllDiscussionsViewController: UIViewController, HasNavigationPermission {
    private var hostingViewController: UIHostingController<EnvironmentWrapperView<AllDiscussionsView>>!
    weak var splitVC: UISplitViewController?
    weak var nvc: UINavigationController?

    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingViewController = UIHostingController(rootView: EnvironmentWrapperView(
            AllDiscussionsView(),
            splitVC: splitViewController ?? splitVC,
            nvc: navigationController ?? nvc,
            vc: self
        ))
        self.hostingViewController = hostingViewController
        addChildViewController(hostingViewController, addConstrains: true)
    }
}
