//
//  PrimaryViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/21.
//

import Combine
import SnapKit
import SwiftUI
import UIKit

extension UIViewController {
    var tabController: TabController? {
        if let tabController = self as? TabController {
            return tabController
        }

        var vc = self
        while let parent = vc.parent {
            if let tabController = parent as? TabController {
                return tabController
            }
            vc = parent
        }
        return nil
    }
}

class TabController: UIViewController {
    private let tabBarHeight: CGFloat = 49.0

    private var currentController: UIViewController?
    private var allDiscussionsViewController = AllDiscussionsViewController()
    private var homeViewController = HomeViewController()
    private var notificationCenterViewController = NotificationCenterViewController()
    private var myProfileViewController = MyProfileCenterViewController()
    private var tabBarViewModel: TabBarViewModel!

    private var tabBarViewController: TabBarViewController!
    private var tabBarHeightConstraint: Constraint?

    private lazy var tabBarItems: [TabItem] = [
        .init(tab: .posts, icon: "message", name: "帖子", color: .teal, viewController: homeViewController),
        .init(tab: .notifications, icon: "bell", name: "通知", color: .red, viewController: notificationCenterViewController),
        .init(tab: .profile, icon: "person", name: "个人资料", color: .blue, viewController: myProfileViewController),
        .init(tab: .setting, icon: "gearshape", name: "设置", color: .gray, viewController: SettingViewController()),
    ]

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

    func select(tab: TabItem.Tab) {
        if let nextVCIndex = tabBarItems.firstIndex(where: { $0.tab == tab }) {
            let nextVC = tabBarItems[nextVCIndex].viewController
            if let currentController = currentController {
                currentController.safelyRemoveFromParent()
            }
            insertChildViewController(nextVC, at: 0, addConstrains: true)
            nextVC.additionalSafeAreaInsets.bottom = tabBarHeight
            currentController = nextVC

            tabBarViewModel.selectedIndex = nextVCIndex
        }
    }

    private func initTabBarViewModel() {
        initViewControllers()
        tabBarViewModel = .init(
            totalWidth: view.frame.width,
            tabBarItems: tabBarItems,
            selectedIndex: 0,
            selectAction: { [weak self] tab in
                if let self = self {
                    self.select(tab: tab)
                }
            }
        )
    }

    private func initViewControllers() {
        allDiscussionsViewController.splitVC = splitViewController
        allDiscussionsViewController.nvc = navigationController

        homeViewController.splitVC = splitViewController
        homeViewController.nvc = navigationController

        notificationCenterViewController.splitVC = splitViewController
        notificationCenterViewController.nvc = navigationController

        myProfileViewController.splitVC = splitViewController
        myProfileViewController.nvc = navigationController
    }
}
