//
//  AppDelegate.swift
//  iOSUIKitPlayground
//
//  Created by 陈俊杰 on 2022/4/3.
//

import UIKit

var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
var isPortrait: Bool { UIDevice.current.orientation.isPortrait }
var isHorizontalCompact: Bool { UITraitCollection.current.horizontalSizeClass == .compact }

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
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
}
