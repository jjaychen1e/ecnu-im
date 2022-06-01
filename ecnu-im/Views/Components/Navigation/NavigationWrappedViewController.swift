//
//  NavigationWrappedViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/6/1.
//

import UIKit

class NavigationWrappedViewController: UIViewController {
    private var innerViewController: UIViewController
    private var isPresented: Bool

    init(viewController: UIViewController, isPresented: Bool) {
        innerViewController = viewController
        self.isPresented = isPresented
        super.init(nibName: nil, bundle: nil)
        let nvc = UINavigationController(rootViewController: viewController)
        addChildViewController(nvc, addConstrains: true)
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
