//
//  MainSplitViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/3.
//

import SwiftUI
import UIKit

class MainSplitViewController: UIViewController {
    @AppStorage("isLogged") var isLogged = false
    @AppStorage("account") var account: String = ""
    @AppStorage("password") var password: String = ""

    static var rootSplitVC: MySplitViewController!

    private var mainSplitViewController: MySplitViewController!

    private lazy var primaryNavigationViewController: NoNavigationBarNavigationController = {
        let nvc = NoNavigationBarNavigationController()
        return nvc
    }()

    private lazy var secondaryNavigationViewController: SecondaryNavigationController = {
        let nvc = SecondaryNavigationController()
        nvc.viewControllers = [DiscussionEmptyViewController.shared]
        return nvc
    }()

    private lazy var primaryViewController = TabController()

    private func adjustSplitViewHierarchy() {
        if UIApplication.shared.isLandscape {
            setOverrideTraitCollection(traitCollection, forChild: mainSplitViewController)
            mainSplitViewController.setOverrideTraitCollectionForAllChildViewControllers(traitCollection)
            if traitCollection.horizontalSizeClass == .compact {
                secondaryNavigationViewController.viewControllers = secondaryNavigationViewController.viewControllers.filter {
                    !($0 is DiscussionEmptyViewController)
                }
                if secondaryNavigationViewController.viewControllers.count == 0,
                   primaryNavigationViewController.topViewController === secondaryNavigationViewController {
                    primaryNavigationViewController.viewControllers = primaryNavigationViewController.viewControllers.dropLast()
                }
            } else if traitCollection.horizontalSizeClass == .regular {
                if let first = secondaryNavigationViewController.viewControllers.first,
                   first is DiscussionEmptyViewController {
                    return
                } else {
                    secondaryNavigationViewController.viewControllers = [DiscussionEmptyViewController.shared] + secondaryNavigationViewController.viewControllers
                }
            }
        } else if UIApplication.shared.isPortrait {
            let tc = UITraitCollection(horizontalSizeClass: .compact)
            setOverrideTraitCollection(tc, forChild: mainSplitViewController)
            mainSplitViewController.setOverrideTraitCollectionForAllChildViewControllers(traitCollection)
            secondaryNavigationViewController.viewControllers = secondaryNavigationViewController.viewControllers.filter {
                !($0 is DiscussionEmptyViewController)
            }
            if secondaryNavigationViewController.viewControllers.count == 0,
               primaryNavigationViewController.topViewController === secondaryNavigationViewController {
                primaryNavigationViewController.viewControllers = primaryNavigationViewController.viewControllers.dropLast()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeApp()

        mainSplitViewController = MySplitViewController(style: .doubleColumn)
        addChildViewController(mainSplitViewController, addConstrains: true)
        primaryNavigationViewController.viewControllers = [primaryViewController]
        mainSplitViewController.setViewController(primaryNavigationViewController, for: .primary)
        mainSplitViewController.maximumPrimaryColumnWidth = 450
        mainSplitViewController.preferredPrimaryColumnWidthFraction = 0.5
        mainSplitViewController.setViewController(secondaryNavigationViewController, for: .secondary)
        mainSplitViewController.preferredDisplayMode = .twoDisplaceSecondary
        primaryViewController.select(tab: .home)
        mainSplitViewController.show(.primary)
        Self.rootSplitVC = mainSplitViewController

        adjustSplitViewHierarchy()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        adjustSplitViewHierarchy()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        adjustSplitViewHierarchy()
    }
}

extension MainSplitViewController {
    func initializeApp() {
        Task {
            if let _ = AppGlobalState.shared.account {
                let loadingToast = LoadingToast(hint: "尝试登录中...")
                loadingToast.show()
                await AppGlobalState.shared.tryToLoginWithStoredAccount()
                loadingToast.hide()
            }
            FlarumBadge.initBadgeInfo()
        }
    }
}
