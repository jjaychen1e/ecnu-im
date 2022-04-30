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
    private var flarumTokenCookie: HTTPCookie?

    static let shared = AppGlobalState()

    func clearCookieStorage() {
        if let cookieStorage = flarumProvider.session.sessionConfiguration.httpCookieStorage,
           let cookies = cookieStorage.cookies(for: URL(string: "https://ecnu.im")!) {
            for cookie: HTTPCookie in cookies {
                cookieStorage.deleteCookie(cookie)
            }
        }
    }

    func logout() {
        clearCookieStorage()
        AppGlobalState.shared.tokenPrepared = false
        AppGlobalState.shared.isLogged = false
        AppGlobalState.shared.account = ""
        AppGlobalState.shared.password = ""
    }

    @discardableResult
    func login(account: String, password: String) async -> Bool {
        if let result = try? await flarumProvider.request(.token(username: account, password: password)),
           let token = try? result.map(Token.self) {
            let flarumTokenCookie = HTTPCookie(properties: [
                HTTPCookiePropertyKey.domain: "ecnu.im",
                HTTPCookiePropertyKey.path: "/",
                HTTPCookiePropertyKey.name: "flarum_remember",
                HTTPCookiePropertyKey.value: token.token,
            ])!
            flarumProvider.session.sessionConfiguration.httpCookieStorage?.setCookie(flarumTokenCookie)
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
                isLogged = false
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
    private lazy var primaryNavigationViewController: UINavigationController = {
        let nvc = UINavigationController()
        return nvc
    }()

    private lazy var secondaryNavigationViewController: UINavigationController = {
        let nvc = UINavigationController()
        return nvc
    }()

    private lazy var sidebarViewController = SettingViewController()
    private lazy var primaryViewController = TabController()

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeApp()

        mainSplitViewController = UISplitViewController(style: .doubleColumn)
        addChildViewController(mainSplitViewController, addConstrains: true)
        mainSplitViewController.setSplitViewRoot(viewController: primaryNavigationViewController, column: .primary)
//        mainSplitViewController.setSplitViewRoot(viewController: sidebarViewController, column: .primary)
        mainSplitViewController.setSplitViewRoot(viewController: primaryViewController, column: .primary)
        mainSplitViewController.maximumPrimaryColumnWidth = 420
        mainSplitViewController.preferredPrimaryColumnWidthFraction = 0.5
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
            FlarumTag.initTagInfo(viewModel: TagsViewModel.shared)
        }
    }
}
