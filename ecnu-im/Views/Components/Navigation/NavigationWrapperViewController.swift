//
//  NavigationWrapperViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/6/1.
//

import SwiftUI
import UIKit

class NavigationWrapperViewController: UIViewController {
    private var innerViewController: UIViewController
    private var isPresented: Bool

    var onDismiss: (() -> Void)?
    var onDoneDismiss: (() -> Void)?

    init(viewController: UIViewController, isPresented: Bool) {
        innerViewController = viewController
        self.isPresented = isPresented
        super.init(nibName: nil, bundle: nil)
        let nvc = UINavigationController(rootViewController: viewController)
        addChildViewController(nvc, addConstrains: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed || parent?.isBeingDismissed == true {
            onDismiss?()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let backImage = UIImage(systemName: "chevron.left")
        let originalLeftBarItems = innerViewController.navigationItem.leftBarButtonItems ?? []
        if !isPresented {
            innerViewController.navigationItem.leftBarButtonItems =
                [
                    UIBarButtonItem(
                        image: backImage,
                        primaryAction: UIAction(
                            handler: { [weak self] action in
                                if let self = self {
                                    if let splitViewController = self.splitViewController {
                                        self.onDoneDismiss?()
                                        splitViewController.pop(from: splitViewController.secondaryNVC)
                                    }
                                }
                            }
                        )
                    ),
                ]
                + originalLeftBarItems
        } else {
            innerViewController.navigationItem.rightBarButtonItems = originalLeftBarItems + [
                UIBarButtonItem(
                    systemItem: .done,
                    primaryAction: UIAction(
                        handler: { [weak self] action in
                            if let self = self {
                                self.onDoneDismiss?()
                                self.dismiss(animated: true)
                            }
                        }
                    )
                ),
            ]
        }

        innerViewController.navigationItem.leftBarButtonItem?.tintColor = Asset
            .DynamicColors
            .dynamicBlack
            .color
            .withAlphaComponent(0.7)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ViewOnDismissModifier: ViewModifier {
    @EnvironmentObject var uiKitEnvironment: UIKitEnvironment

    private let action: (() -> Void)?

    init(perform action: (() -> Void)? = nil) {
        self.action = action
    }

    func body(content: Content) -> some View {
        content
            .onLoad {
                let originalOnDismiss = uiKitEnvironment.navWrapperVC?.onDismiss
                uiKitEnvironment.navWrapperVC?.onDismiss = {
                    originalOnDismiss?()
                    action?()
                }
            }
    }
}

extension View {
    func onDismiss(perform action: (() -> Void)? = nil) -> some View {
        modifier(ViewOnDismissModifier(perform: action))
    }
}

struct ViewOnDoneDismissModifier: ViewModifier {
    @EnvironmentObject var uiKitEnvironment: UIKitEnvironment

    private let action: (() -> Void)?

    init(perform action: (() -> Void)? = nil) {
        self.action = action
    }

    func body(content: Content) -> some View {
        content
            .onLoad {
                let originalOnDoneDismiss = uiKitEnvironment.navWrapperVC?.onDoneDismiss
                uiKitEnvironment.navWrapperVC?.onDoneDismiss = {
                    originalOnDoneDismiss?()
                    action?()
                }
            }
    }
}

extension View {
    func onDoneDismiss(perform action: (() -> Void)? = nil) -> some View {
        modifier(ViewOnDoneDismissModifier(perform: action))
    }
}
