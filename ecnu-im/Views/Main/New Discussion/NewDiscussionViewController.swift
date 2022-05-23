//
//  NewDiscussionViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/23.
//

import UIKit
import SwiftUI

class NewDiscussionViewController: UIViewController, HasNavigationPermission {
    private var hostingViewController: UIHostingController<EnvironmentWrapperView<NewDiscussionView>>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingViewController = UIHostingController(rootView: EnvironmentWrapperView(
            NewDiscussionView(),
            splitVC: splitViewController,
            nvc: navigationController,
            vc: self
        ))
        self.hostingViewController = hostingViewController
        addChildViewController(hostingViewController, addConstrains: true)
    }
}
