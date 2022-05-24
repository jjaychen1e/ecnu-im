//
//  AppDelegate.swift
//  iOSUIKitPlayground
//
//  Created by 陈俊杰 on 2022/4/3.
//

import UIKit

class MyApplication: UIApplication {
    override func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:], completionHandler completion: ((Bool) -> Void)? = nil) {
        if url.absoluteString.hasPrefix(URLService.scheme) {
            if let urlService = url.urlService {
                switch urlService {
                case let .safari(href):
                    // Open in Safari:
                    if let url = URL(string: href) {
                        super.open(url, options: options, completionHandler: completion)
                    }
                default:
                    super.open(url, options: options, completionHandler: completion)
                }
            }
        } else {
            if !["http", "https"].contains(URLComponents(url: url, resolvingAgainstBaseURL: true)?.scheme) {
                super.open(url, options: options, completionHandler: completion)
            } else {
                // As a normal link
                if let escapedURL = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
                   let url = URLService.link(href: escapedURL).url.url {
                    super.open(url, options: options, completionHandler: completion)
                }
            }
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UITextView.appearance().backgroundColor = .clear
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_: UIApplication, didDiscardSceneSessions _: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func applicationWillEnterForeground(_: UIApplication) {
        Task {
            await AppGlobalState.shared.tryToLoginWithStoredAccount()
        }
    }
}

extension UIApplication {
    func topController() -> UIViewController? {
        let keyWindow = sceneWindows.filter { $0.isKeyWindow }.first

        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return nil
    }

    var sceneWindows: [UIWindow] {
        UIApplication.shared.connectedScenes
            .first(where: { $0 is UIWindowScene })
            .flatMap { $0 as? UIWindowScene }?.windows ?? []
    }

    func presentOnTop(_ viewController: UIViewController, animated: Bool = true) {
        if let hasNavigationPermission = viewController as? HasNavigationPermission {
            switch hasNavigationPermission.navigationPermission() {
            case .login:
                if !AppGlobalState.shared.tokenPrepared {
                    topController()?.presentSignView()
                    return
                }
            }
        }
        topController()?.present(viewController, animated: animated)
    }
}
