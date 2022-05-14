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

    static var rootSplitVC: UISplitViewController!

    private var mainSplitViewController: UISplitViewController!

    private lazy var emptyViewController: DiscussionEmptyViewController = .init()

    private lazy var primaryNavigationViewController: UINavigationController = {
        let nvc = UINavigationController()
        return nvc
    }()

    private lazy var secondaryNavigationViewController: UINavigationController = {
        let nvc = UINavigationController()
        nvc.viewControllers = [emptyViewController]
        return nvc
    }()

    private lazy var primaryViewController = TabController()

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeApp()

        mainSplitViewController = UISplitViewController(style: .doubleColumn)
        addChildViewController(mainSplitViewController, addConstrains: true)
        primaryNavigationViewController.viewControllers = [primaryViewController]
        mainSplitViewController.setViewController(primaryNavigationViewController, for: .primary)
        mainSplitViewController.maximumPrimaryColumnWidth = 450
        mainSplitViewController.preferredPrimaryColumnWidthFraction = 0.5
        mainSplitViewController.setViewController(secondaryNavigationViewController, for: .secondary)
        mainSplitViewController.preferredDisplayMode = .twoDisplaceSecondary
        mainSplitViewController.show(.primary)
        Self.rootSplitVC = mainSplitViewController

        traitCollectionDidChange(traitCollection)
    }

    // TODO: init will not trigger this!
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
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
                secondaryNavigationViewController.viewControllers = [emptyViewController] + secondaryNavigationViewController.viewControllers
            }
        }
    }
}

extension MainSplitViewController {
    func initializeApp() {
        fetchTags()
        Task {
            await AppGlobalState.shared.tryToLoginWithStoredAccount()
        }
    }

    private func fetchTags() {
        Task {
            FlarumTag.initTagInfo(viewModel: TagsViewModel.shared)
        }
    }
}
