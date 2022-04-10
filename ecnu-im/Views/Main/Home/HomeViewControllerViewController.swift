//
//  HomeViewControllerViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/22.
//

import SwiftUI
import UIKit

class HomeViewControllerViewController: NoNavigationBarViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.isNavigationBarHidden = true

        let vc = UIHostingController(rootView: HomeView())
        addChildViewController(vc, addConstrains: true)
    }
}
