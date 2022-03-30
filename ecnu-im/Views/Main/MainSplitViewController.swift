//
//  MainSplitViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/3.
//

import SwiftUI
import UIKit

class AppGlobalState: ObservableObject {
    @Published var tokenPrepared = false

    static let shared = AppGlobalState()
}

class MainSplitViewController: UIViewController {
    private var mainSplitViewController: UISplitViewController!
    private lazy var primaryViewController: UINavigationController = {
        let nvc = UINavigationController()
        return nvc
    }()

    private lazy var supplementaryNavigationViewController: UINavigationController = {
        let nvc = UINavigationController()
        return nvc
    }()

    private lazy var secondaryNavigationViewController: UINavigationController = {
        let nvc = UINavigationController()
        return nvc
    }()

    private lazy var sidebarViewController = SidebarViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeApp()

        mainSplitViewController = UISplitViewController(style: .tripleColumn)
        addSubViewController(mainSplitViewController, addConstrains: true)
        mainSplitViewController.setSplitViewRoot(viewController: primaryViewController, column: .primary)
        mainSplitViewController.setSplitViewRoot(viewController: sidebarViewController, column: .primary)
        mainSplitViewController.setSplitViewRoot(viewController: supplementaryNavigationViewController, column: .supplementary)
        mainSplitViewController.setSplitViewRoot(viewController: secondaryNavigationViewController, column: .secondary)
        mainSplitViewController.preferredDisplayMode = .twoDisplaceSecondary
        mainSplitViewController.show(.primary)
    }
}

extension MainSplitViewController {
    func initializeApp() {
        login()
        fetchTags()
    }

    private func login() {
        Task {
            if let result = try? await flarumProvider.request(.token(username: "jjaychen", password: "password")),
               let token = try? result.map(Token.self) {
                token.persist()
                let httpCookie = HTTPCookie(properties: [
                    HTTPCookiePropertyKey.domain: "ecnu.im",
                    HTTPCookiePropertyKey.path: "/",
                    HTTPCookiePropertyKey.name: "flarum_remember",
                    HTTPCookiePropertyKey.value: token.token,
                ])!
                flarumProvider.session.sessionConfiguration.httpCookieStorage?.setCookie(httpCookie)
            }
            AppGlobalState.shared.tokenPrepared = true
        }
    }

    private func fetchTags() {
        Task {
            Tag.initTagInfo(viewModel: TagsViewModel.shared)
        }
    }
}
