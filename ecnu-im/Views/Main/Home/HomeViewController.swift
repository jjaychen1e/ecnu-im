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

    private var hostingVC: UIHostingController<EnvironmentWrapperView<HomeView>>!

    override func viewDidLoad() {
        super.viewDidLoad()

        let vc = UIHostingController(rootView: EnvironmentWrapperView(
            HomeView(),
            splitVC: splitViewController ?? splitVC,
            nvc: navigationController ?? nvc,
            vc: self
        ), disableKeyboardNotification: true)
        hostingVC = vc
        addChildViewController(vc, addConstrains: false)
        vc.view.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
        }
    }
}
