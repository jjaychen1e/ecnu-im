//
//  HomeConfigureViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/6/1.
//

import SwiftUI
import UIKit

class HomeConfigureViewController: UIViewController, NoOverlayViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let vc = NavigationWrappedViewController(viewController: InnerHomeConfigureViewController(), isPresented: isBeingPresented)
        addChildViewController(vc, addConstrains: true)
    }
}

private class InnerHomeConfigureViewController: SettingViewController, NoOverlayViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "首页模块配置"
    }

    private var dataSourceLoaded = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !dataSourceLoaded {
            dataSourceLoaded = true
            DispatchQueue.main.async { [weak self] in
                if let self = self {
                    self.modelObjects = [
                        HeaderItem.hidden(rowItems: [
                            RowItem(type: .toggle(action: { value in
                                                      AppGlobalState.shared.showRecentActiveUsers.send(value)
                                                  },
                                                  publisher: AppGlobalState.shared.showRecentActiveUsers.eraseToAnyPublisher()),
                                    icon: .system(name: "person.crop.circle"),
                                    label: "最近活跃用户"),
                            RowItem(type: .toggle(action: { value in
                                                      AppGlobalState.shared.showRecentOnlineUsers.send(value)
                                                  },
                                                  publisher: AppGlobalState.shared.showRecentOnlineUsers.eraseToAnyPublisher()),
                                    icon: .uiImage(uiImage: {
                                        let config = UIImage.SymbolConfiguration(paletteColors: [UIColor("#7FBA00"), Asset.DynamicColors.dynamicBlack.color])
                                        let image = UIImage(systemName: "person.crop.circle.badge", withConfiguration: config)!
                                        return image
                                    }(), color: nil),
                                    label: "最近在线用户（若有权限）"),
                            RowItem(type: .toggle(action: { value in
                                                      AppGlobalState.shared.showRecentRegisteredUsers.send(value)
                                                  },
                                                  publisher: AppGlobalState.shared.showRecentRegisteredUsers.eraseToAnyPublisher()),
                                    icon: .system(name: "person.crop.circle.badge.plus"),
                                    label: "最近注册用户（若有权限）"),
                        ]),
                    ]
                    self.applyInitialSnapshots()
                }
            }
        }
    }
}
