//
//  AppGlobalState.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/14.
//

import Foundation
import SwiftUI

class AppGlobalState: ObservableObject {
    @AppStorage("isLogged") var isLogged = false
    @AppStorage("account") var account: String = ""
    @AppStorage("userId") var userId: String = ""
    @AppStorage("password") var password: String = ""
    @Published var unreadNotificationCount = 0
    @Published var tokenPrepared = false
    @Published var userInfo: FlarumUser?
    @Published var ignoredUserIds: Set<String> = []
    private var flarumTokenCookie: HTTPCookie?

    var userIdInt: Int? {
        if let userIdInt = Int(userId) {
            return userIdInt
        }
        return nil
    }

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
        AppGlobalState.shared.unreadNotificationCount = 0
        AppGlobalState.shared.isLogged = false
        AppGlobalState.shared.account = ""
        AppGlobalState.shared.userId = ""
        AppGlobalState.shared.password = ""
    }

    @discardableResult
    func login(account: String, password: String) async -> Bool {
        if let result = try? await flarumProvider.request(.token(username: account, password: password)) {
            if let token = try? result.map(Token.self) {
                let flarumTokenCookie = HTTPCookie(properties: [
                    HTTPCookiePropertyKey.domain: "ecnu.im",
                    HTTPCookiePropertyKey.path: "/",
                    HTTPCookiePropertyKey.name: "flarum_remember",
                    HTTPCookiePropertyKey.value: token.token,
                ])!
                flarumProvider.session.sessionConfiguration.httpCookieStorage?.setCookie(flarumTokenCookie)
                DispatchQueue.main.async {
                    AppGlobalState.shared.userId = "\(token.userId)"
                    self.tokenPrepared = true
                }
                if let response = try? await flarumProvider.request(.user(id: token.userId)).flarumResponse() {
                    if AppGlobalState.shared.userInfo == nil {
                        DispatchQueue.main.async {
                            AppGlobalState.shared.userInfo = response.data.users.first
                        }
                    }
                    FlarumBadgeStorage.shared.store(userBadges: response.included.userBadges)
                    DispatchQueue.main.async {
                        AppGlobalState.shared.ignoredUserIds = Set(response.data.users.first?.relationships?.ignoredUsers.compactMap { $0.id } ?? [])
                    }
                }
                return true
            } else {
                debugExecution {
                    print(String(data: result.data, encoding: .utf8) ?? "failed")
                    fatalErrorDebug()
                }
            }
        }
        return false
    }

    func tryToLoginWithStoredAccount() async {
        if isLogged {
            let loginResult = await login(account: account, password: password)
            if !loginResult {
                // Maybe password has been modified
                await UIApplication.shared.topController()?.presentSignView()
                logout()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    Toast.default(icon: .emoji("🤔"), title: "登录失败", subtitle: "密码可能被修改，请重新登录").show()
                }
            }
        }
    }
}
