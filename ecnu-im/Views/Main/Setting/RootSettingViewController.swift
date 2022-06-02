//
//  RootSettingViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/6/1.
//

import UIKit

class RootSettingViewController: SettingViewController {
    override func viewDidLoad() {
        modelObjects = [
            HeaderItem(title: "论坛", rowItems: [
                RowItem(type: .toggle(action: { value in
                                          AppGlobalState.shared.blockCompletely.send(value)
                                      },
                                      publisher: AppGlobalState.shared.blockCompletely.eraseToAnyPublisher()),
                        icon: .system(name: "person.crop.circle.badge.minus"), label: "完全隐藏屏蔽用户"),
                RowItem(type: .toggle(action: { value in
                                          AppGlobalState.shared.autoClearUnreadNotification.send(value)
                                      },
                                      publisher: AppGlobalState.shared.autoClearUnreadNotification.eraseToAnyPublisher()),
                        icon: .system(name: "bell.badge"), label: "自动已读通知"),
                RowItem(type: .navigation(action: {
                    if let url = URL(string: URLService.link(href: "https://ecnu.im/p/2-FAQ").url) {
                        UIApplication.shared.open(url)
                    }
                }), icon: .system(name: "questionmark.circle"), label: "论坛常见问题"),
                RowItem(type: .navigation(action: {
                    if let url = URL(string: URLService.link(href: "https://ecnu.im/d/287").url) {
                        UIApplication.shared.open(url)
                    }
                }), icon: .system(name: "newspaper"), label: "论坛守则"),
                RowItem(type: .navigation(action: {
                    if let url = URL(string: URLService.link(href: "https://discord.gg/a9NBjHwBEQ").url) {
                        UIApplication.shared.open(url)
                    }
                }), icon: .uiImage(uiImage: Asset.Icons.discord.image), label: "Discord 小组"),
                RowItem(type: .navigation(action: {
                    if let url = URL(string: URLService.link(href: "https://ecnu.im").url) {
                        UIApplication.shared.open(url)
                    }
                }), icon: .system(name: "safari"), label: "网页版论坛"),
            ]),
            HeaderItem(title: "样式", rowItems: [
                RowItem(type: .segmentedControl(actions: ThemeStyleOption.allCases.map { option in
                            UIAction(title: option.rawValue) { _ in
                                AppGlobalState.shared.themeStyleOption.send(option)
                            }
                        },
                        publisher: AppGlobalState.shared.themeStyleOption
                            .compactMap { value -> Int? in ThemeStyleOption.allCases.firstIndex(of: value) }
                            .eraseToAnyPublisher()),
                        icon: .system(name: "moon.stars"),
                        label: "主题"),
                RowItem(type: .navigation(action: { [weak self] in
                    if let self = self, let splitViewController = self.splitViewController {
                        splitViewController.push(viewController: HomeConfigureViewController(), column: .secondary, toRoot: true)
                    } else {
                        fatalErrorDebug()
                    }
                }),
                icon: .system(name: "house"),
                label: "首页模块配置"),
            ]),
            HeaderItem(title: "小功能", rowItems: [
                RowItem(type: .navigation(action: {
                    if let url = URL(string: URLService.link(href: "https://u-office.ecnu.edu.cn/xiaoli/").url) {
                        UIApplication.shared.open(url)
                    }
                }), icon: .system(name: "calendar"), label: "校历"),
                RowItem(type: .navigation(action: {
                    if let url = URL(string: URLService.link(href: "http://www.ecard.ecnu.edu.cn/").url) {
                        UIApplication.shared.open(url)
                    }
                }), icon: .system(name: "creditcard"), label: "校园卡中心"),
                RowItem(type: .navigation(action: {
                    Toast.default(icon: .emoji("👀"), title: "尚未支持").show()
                }), icon: .system(name: "calendar.badge.plus"), label: "导入课表至日历"),
            ]),
            HeaderItem(title: "其他", rowItems: [
                RowItem(type: .navigation(action: {
                    if let url = URL(string: URLService.link(href: "https://github.com/JJAYCHEN1e/ecnu-im").url) {
                        UIApplication.shared.open(url)
                    }
                }), icon: .system(name: "chevron.left.forwardslash.chevron.right"), label: "GitHub 仓库"),
                RowItem(type: .navigation(action: { [weak self] in
                    if let self = self, let splitViewController = self.splitViewController {
                        let vc = AcknowledgementViewController()
                        vc.splitVC = splitViewController
                        vc.nvc = splitViewController.secondaryNVC
                        if splitViewController.isCollapsed == true {
                            UIApplication.shared.presentOnTop(vc)
                        } else {
                            splitViewController.push(viewController: vc, column: .secondary, toRoot: true)
                        }
                    } else {
                        fatalErrorDebug()
                    }
                }), icon: .system(name: "list.bullet.rectangle"), label: "致谢"),
            ]),
            HeaderItem(title: "账户", rowItems: [
                RowItem(type: .navigation(action: {
                    if let url = URL(string: URLService.link(href: "https://ecnu.im/settings").url) {
                        UIApplication.shared.open(url)
                    }
                }), icon: .system(name: "person.crop.circle"), label: "修改资料"),
                RowItem(type: .action(action: { sender in
                    let alertController = UIAlertController(title: "你确定要退出登录吗", message: nil, preferredStyle: .actionSheet)
                    alertController.addAction(.init(title: "退出登录", style: .destructive, handler: { _ in
                        AppGlobalState.shared.logout()
                    }))
                    alertController.addAction(.init(title: "取消", style: .cancel, handler: { _ in
                        alertController.dismiss(animated: true)
                    }))
                    if let popoverController = alertController.popoverPresentationController {
                        popoverController.sourceView = sender // to set the source of your alert
                    }
                    self.present(alertController, animated: true)
                }),
                label: "退出登录", textColor: .systemRed),
            ]),
        ]
        super.viewDidLoad()
    }
}
