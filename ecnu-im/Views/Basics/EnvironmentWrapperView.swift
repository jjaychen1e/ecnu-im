//
//  EnvironmentWrapperView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/14.
//

import SwiftUI

private struct UIKitEnvironmentKey: EnvironmentKey {
    static let defaultValue: UIKitEnvironment = .init(splitVC: nil, nvc: nil, vc: nil)
}

extension EnvironmentValues {
    var uiKitEnvironment: UIKitEnvironment {
        get { self[UIKitEnvironmentKey.self] }
        set { self[UIKitEnvironmentKey.self] = newValue }
    }
}

class UIKitEnvironment: ObservableObject {
    weak var splitVC: UISplitViewController?
    weak var nvc: UINavigationController?
    weak var vc: UIViewController?

    init(splitVC: UISplitViewController?, nvc: UINavigationController?, vc: UIViewController?) {
        self.splitVC = splitVC
        self.nvc = nvc
        self.vc = vc
    }

    func update(splitVC: UISplitViewController?, nvc: UINavigationController?, vc: UIViewController?) {
        self.splitVC = splitVC
        self.nvc = nvc
        self.vc = vc
    }
}

struct EnvironmentWrapperView<Content: View>: View {
    @ObservedObject var uiKitEnvironment: UIKitEnvironment

    var view: Content

    init(_ content: Content, splitVC: UISplitViewController?, nvc: UINavigationController?, vc: UIViewController?) {
        view = content
        uiKitEnvironment = UIKitEnvironment(splitVC: splitVC, nvc: nvc, vc: vc)
    }

    var body: some View {
        view
            .environmentObject(uiKitEnvironment)
            .environment(\.openURL, OpenURLAction { url in
                if url.absoluteString.hasPrefix(URLService.scheme) {
                    // Our scheme
                    UIApplication.shared.open(url)
                } else {
                    // As a normal link
                    if let url = URLService.link(href: url.absoluteString).url.url {
                        UIApplication.shared.open(url)
                    }
                }
                return .handled
            })
    }

    func update(splitVC: UISplitViewController?, nvc: UINavigationController?, vc: UIViewController?) {
        uiKitEnvironment.update(splitVC: splitVC, nvc: nvc, vc: vc)
    }
}
