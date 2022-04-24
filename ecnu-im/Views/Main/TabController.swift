//
//  PrimaryViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/21.
//

import SnapKit
import SwiftUI
import UIKit

class TabController: UIViewController {
    private let tabBarHeight: CGFloat = 49.0
    
    private var currentController: UIViewController?
    private var allDiscussionsViewController = AllDiscussionsViewController()
    private var homeViewController = HomeViewController()
    private var tabBarViewModel: TabBarViewModel2!

    private var tabBarViewController: TabBarViewController!
    private var tabBarHeightConstraint: Constraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        setTabBar()
    }

    override func viewWillLayoutSubviews() {
        tabBarViewModel.totalWidth = view.frame.width

        tabBarHeightConstraint?.deactivate()
        tabBarHeightConstraint = nil
        tabBarViewController.view.snp.makeConstraints { make in
            tabBarHeightConstraint = make.height.equalTo(currentTabBarHeight).constraint
        }
    }

    private var currentTabBarHeight: CGFloat {
        view.safeAreaInsets.bottom + tabBarHeight
    }

    private func setTabBar() {
        initTabBarViewModel()

        let tabBarVC = TabBarViewController(viewModel: tabBarViewModel)
        tabBarViewController = tabBarVC
        addChildViewController(tabBarVC, addConstrains: false)
        tabBarVC.view.snp.makeConstraints { make in
            make.left.bottom.trailing.equalToSuperview()
            tabBarHeightConstraint = make.height.equalTo(currentTabBarHeight).constraint
        }
    }

    private func initTabBarViewModel() {
        initViewControllers()
        let tabBarItems: [TabItem] = [
            .init(tab: .posts, icon: "message", name: "帖子", color: .teal, viewController: homeViewController),
            .init(tab: .notifications, icon: "bell", name: "通知", color: .red, viewController: allDiscussionsViewController),
            .init(tab: .profile, icon: "person", name: "个人资料", color: .blue, viewController: SidebarViewController()),
            .init(tab: .setting, icon: "gearshape", name: "设置", color: .gray, viewController: SidebarViewController()),
        ]
        tabBarViewModel = .init(
            totalWidth: view.frame.width,
            tabBarItems: tabBarItems,
            selectedIndex: 0,
            selectAction: { tab in
                if let nextVC = tabBarItems.first(where: { $0.tab == tab })?.viewController {
                    if let currentController = self.currentController {
                        currentController.safelyRemoveFromParent()
                    }
                    self.insertChildViewController(nextVC, at: 0, addConstrains: true)
                    nextVC.additionalSafeAreaInsets.bottom = self.tabBarHeight
                    self.currentController = nextVC
                }
            }
        )
    }

    private func initViewControllers() {
        allDiscussionsViewController.splitVC = splitViewController
        allDiscussionsViewController.nvc = navigationController
        
        homeViewController.splitVC = splitViewController
        homeViewController.nvc = navigationController
    }
}
