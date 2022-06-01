//
//  HomeConfigureViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/6/1.
//

import SwiftUI
import UIKit

class HomeConfigureViewController: SettingViewController, NoOverlayViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.async { [weak self] in
            if let self = self {
                self.modelObjects = [
                    HeaderItem.normal(title: "首页模块配置", rowItems: [
                        RowItem(type: .toggle(action: { value in
                                                  AppGlobalState.shared.showRecentActiveUsers.send(value)
                                              },
                                              publisher: AppGlobalState.shared.showRecentActiveUsers.eraseToAnyPublisher()),
                                icon: .uiImage(
                                    uiImage: Image(systemName: "person.crop.circle")
                                        .frame(width: 24, height: 24)
                                        .snapshot(),
                                    color: nil
                                ),
                                label: "最近活跃用户"),
                        RowItem(type: .toggle(action: { value in
                                                  AppGlobalState.shared.showRecentOnlineUsers.send(value)
                                              },
                                              publisher: AppGlobalState.shared.showRecentOnlineUsers.eraseToAnyPublisher()),
                                icon: .uiImage(
                                    uiImage: Image(systemName: "person.crop.circle.badge")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(Color(rgba: "#7FBA00"), .primary)
                                        .frame(width: 24, height: 24)
                                        .snapshot(),
                                    color: nil
                                ),
                                label: "最近在线用户（若有权限）"),
                        RowItem(type: .toggle(action: { value in
                                                  AppGlobalState.shared.showRecentRegisteredUsers.send(value)
                                              },
                                              publisher: AppGlobalState.shared.showRecentRegisteredUsers.eraseToAnyPublisher()),
                                icon: .uiImage(
                                    uiImage: Image(systemName: "person.crop.circle.badge.plus")
                                        .frame(width: 24, height: 24)
                                        .snapshot(),
                                    color: nil
                                ),
                                label: "最近注册用户（若有权限）"),
                    ]),
                ]
                self.applyInitialSnapshots()
            }
        }
    }
}
