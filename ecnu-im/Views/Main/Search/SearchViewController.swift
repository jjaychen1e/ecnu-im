//
//  SearchViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/23.
//

import SwiftUI
import UIKit

class SearchViewController: UIViewController {
    private var hostingViewController: UIHostingController<EnvironmentWrapperView<SearchView>>!

    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingViewController = UIHostingController(rootView: EnvironmentWrapperView(
            SearchView(),
            splitVC: splitViewController,
            nvc: navigationController,
            vc: self
        ))
        self.hostingViewController = hostingViewController
        addChildViewController(hostingViewController, addConstrains: true)
    }
}
