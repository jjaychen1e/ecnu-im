//
//  AppGlobalState.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/14.
//

import Combine
import Foundation
import SwiftUI

struct Account: Codable {
    var account: String
    var password: String
    var userId: Int

    var userIdString: String {
        "\(userId)"
    }
}

/// https://stackoverflow.com/a/68795484
extension Optional: RawRepresentable where Wrapped: Codable {
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let json = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return json
    }

    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let value = try? JSONDecoder().decode(Self.self, from: data)
        else {
            return nil
        }
        self = value
    }
}

class AppGlobalState: ObservableObject {
    @AppStorage("account") private(set) var account: Account? = nil

    public var blockCompletely: CurrentValueSubject<Bool, Never>
    public var themeStyleOption: CurrentValueSubject<ThemeStyleOption, Never>

    @Published var unreadNotificationCount = 0
    @Published var userInfo: FlarumUser?
    @Published var ignoredUserIds: Set<String> = []
    @Published var hasTriedToLogin = false
    @Published var token: String? = nil
    @Published var tokenPrepared = false

    var emailVerificationEvent = PassthroughSubject<Void, Never>()
    var clearNotificationEvent = PassthroughSubject<Void, Never>()

    private var subscriptions: Set<AnyCancellable> = []

    var userIdInt: Int? {
        if let account = account {
            return account.userId
        }
        return nil
    }

    var flarumCookie: HTTPCookie? {
        if let token = token, let flarumTokenCookie = HTTPCookie(properties: [
            HTTPCookiePropertyKey.domain: "ecnu.im",
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.name: "flarum_remember",
            HTTPCookiePropertyKey.value: token,
        ]) {
            return flarumTokenCookie
        }
        return nil
    }

    static let shared = AppGlobalState()

    init() {
        blockCompletely = CurrentValueSubject<Bool, Never>(UserDefaults.standard.bool(forKey: "blockCompletely"))
        themeStyleOption = {
            if let rawString = UserDefaults.standard.string(forKey: "themeStyleOption"),
               let themeStyleOption = ThemeStyleOption(rawValue: rawString) {
                return CurrentValueSubject<ThemeStyleOption, Never>(themeStyleOption)
            } else {
                return CurrentValueSubject<ThemeStyleOption, Never>(.auto)
            }
        }()

        blockCompletely.sink { value in
            UserDefaults.standard.set(value, forKey: "blockCompletely")
            self.objectWillChange.send()
        }
        .store(in: &subscriptions)
        themeStyleOption.sink { value in
            switch value {
            case .auto:
                UIApplication.shared.sceneWindows.forEach { window in
                    window.overrideUserInterfaceStyle = .unspecified
                }
            case .light:
                UIApplication.shared.sceneWindows.forEach { window in
                    window.overrideUserInterfaceStyle = .light
                }
            case .dark:
                UIApplication.shared.sceneWindows.forEach { window in
                    window.overrideUserInterfaceStyle = .dark
                }
            }
            UserDefaults.standard.set(value.rawValue, forKey: "themeStyleOption")
            self.objectWillChange.send()
        }
        .store(in: &subscriptions)

        emailVerificationEvent.sink { _ in
            Task {
                await self.tryToLoginWithStoredAccount()
            }
        }
        .store(in: &subscriptions)
    }

    func clearCookieStorage() {
        flarumProvider.session.session.reset(completionHandler: {})
    }

    func logout() {
        clearCookieStorage()
        account = nil
        unreadNotificationCount = 0
        userInfo = nil
        ignoredUserIds = []
        token = nil
        tokenPrepared = false
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
                    self.account = Account(account: account, password: password, userId: token.userId)
                    self.hasTriedToLogin = true
                    self.token = token.token
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
            } else if let error = try? result.map(FlarumAPIErrorModel.self) {
                debugPrint(error)
            } else {
                debugExecution {
                    print(String(data: result.data, encoding: .utf8) ?? "failed")
                    fatalErrorDebug()
                }
            }
        }
        DispatchQueue.main.async {
            self.hasTriedToLogin = true
        }
        return false
    }

    func tryToLoginWithStoredAccount() async {
        if let account = account {
            let loginResult = await login(account: account.account, password: account.password)
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
