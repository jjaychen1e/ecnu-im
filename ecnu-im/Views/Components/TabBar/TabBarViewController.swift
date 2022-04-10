//
//  TabBarViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/22.
//

import SnapKit
import SwiftUI
import UIKit

class TabBarViewController: UIViewController {
    private var viewModel: TabBarViewModel2

    init(viewModel: TabBarViewModel2) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let tabBarContentVC = UIHostingController(rootView: TabBarContentView(viewModel: viewModel))
        tabBarContentVC.view.backgroundColor = .clear
        addChildViewController(tabBarContentVC)
        tabBarContentVC.view.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
}
