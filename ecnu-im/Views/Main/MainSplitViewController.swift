//
//  MainSplitViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/3.
//

import SwiftUI
import UIKit

class AppGlobalState: ObservableObject {
    @AppStorage("isLogged") var isLogged = false
    @AppStorage("account") var account: String = ""
    @AppStorage("password") var password: String = ""
    @Published var tokenPrepared = false

    static let shared = AppGlobalState()

    @discardableResult
    func login(account: String, password: String) async -> Bool {
        if let result = try? await flarumProvider.request(.token(username: account, password: password)),
           let token = try? result.map(Token.self) {
            let httpCookie = HTTPCookie(properties: [
                HTTPCookiePropertyKey.domain: "ecnu.im",
                HTTPCookiePropertyKey.path: "/",
                HTTPCookiePropertyKey.name: "flarum_remember",
                HTTPCookiePropertyKey.value: token.token,
            ])!
            flarumProvider.session.sessionConfiguration.httpCookieStorage?.setCookie(httpCookie)
            DispatchQueue.main.async {
                self.tokenPrepared = true
            }
            return true
        }
        return false
    }

    func tryToLoginWithStoredAccount() async {
        if isLogged {
            let loginResult = await login(account: account, password: password)
            if !loginResult {
                // Maybe password has been modified
                await MainSplitViewController.rootSplitVC.presentSignView()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    Toast.default(icon: .emoji("🤔"), title: "登录失败", subtitle: "密码可能被修改，请重新登录").show()
                }
            }
        }
    }
}

class MainSplitViewController: UIViewController {
    @AppStorage("isLogged") var isLogged = false
    @AppStorage("account") var account: String = ""
    @AppStorage("password") var password: String = ""

    static var rootSplitVC: UISplitViewController!

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
        Self.rootSplitVC = mainSplitViewController
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
            Tag.initTagInfo(viewModel: TagsViewModel.shared)
        }
    }
}
