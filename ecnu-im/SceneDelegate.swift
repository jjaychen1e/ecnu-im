//
//  SceneDelegate.swift
//  iOSUIKitPlayground
//
//  Created by 陈俊杰 on 2022/4/3.
//

import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var lastTimeEnterBackground: Date?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        let rootViewController = MainSplitViewController()
//        let rootViewController = UIHostingController(rootView: EditorView())
        window.rootViewController = rootViewController

        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        if let lastTimeEnterBackground = lastTimeEnterBackground {
            let timeDifferenceInSeconds = Date().timeIntervalSince(lastTimeEnterBackground)
            self.lastTimeEnterBackground = nil
            if timeDifferenceInSeconds > 60 * 10 {
                Task {
                    if let _ = AppGlobalState.shared.account {
                        let loadingToast = LoadingToast(hint: "重新登录中...")
                        loadingToast.show()
                        await AppGlobalState.shared.tryToLoginWithStoredAccount()
                        loadingToast.hide()
                    }
                }
            }
        }
    }

    func sceneDidEnterBackground(_: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        lastTimeEnterBackground = Date()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }

        if let urlService = url.urlService {
            switch urlService {
            case let .link(href, jsAction):
                if let url = URL(string: href) {
                    CommonWebViewController.show(url: url, jsActionOnLoad: jsAction)
                }
            case .safari:
                // Never, never happened
                fatalErrorDebug()
                UIApplication.shared.open(url)
            }
        }
    }
}

enum URLServiceType: String, RawRepresentable {
    case link
    case safari
}

enum URLService {
    static let scheme = "ecnu-im"

    case link(href: String, jsAction: String? = nil)
    case safari(href: String)

    var schemePrefix: String {
        Self.scheme + "://"
    }

    var url: String {
        switch self {
        case let .link(href, jsAction):
            return schemePrefix + "link?" + "href=\(href.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")" +
                "&jsAction=\(jsAction?.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")"
        case let .safari(href):
            return schemePrefix + "safari?" + "href=\(href.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")"
        }
    }
}

extension URL {
    var urlService: URLService? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let scheme = components.scheme,
              let host = components.host,
              let params = components.queryItems
        else { return nil }

        // URLComponents already decode url once
        if let urlService = URLServiceType(rawValue: host) {
            switch urlService {
            case .link:
                if let href = params.first(where: { $0.name == "href" })?.value,
                   let url = URL(string: href) {
                    let jsAction = params.first(where: { $0.name == "jsAction" })?.value
                    return .link(href: href, jsAction: jsAction)
                }
            case .safari:
                if let href = params.first(where: { $0.name == "href" })?.value,
                   let url = URL(string: href) {
                    return .safari(href: href)
                }
            }
        }

        return nil
    }
}
