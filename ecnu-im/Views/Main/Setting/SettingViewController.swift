//
//  SettingViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/3.
//

import Combine
import SnapKit
import SwiftUI
import UIKit

private enum ListItem: Hashable {
    case header(HeaderItem)
    case rowItem(RowItem)
}

// Header cell data type
private struct HeaderItem: Hashable {
    let title: String
    let rowItems: [RowItem]
}

private enum RowType {
    case navigation(action: () -> Void)
    case action(action: (_ sender: UIView) -> Void)
    case toggle(action: (Bool) -> Void, publisher: AnyPublisher<Bool, Never>)
    case segmentedControl(actions: [UIAction], publisher: AnyPublisher<Int, Never>)

    // TODO: drop down
}

private enum RowIcon {
    case system(name: String, color: UIColor? = nil)
    case uiImage(uiImage: UIImage, color: UIColor? = nil)
    case image(name: String, color: UIColor? = nil)

    func toUIImage() -> UIImage? {
        switch self {
        case let .image(name, color):
            return UIImage(named: name)?.withTintColor(color ?? Asset.DynamicColors.dynamicBlack.color).withRenderingMode(.alwaysOriginal)
        case let .system(name, color):
            return UIImage(systemName: name)?.withTintColor(color ?? Asset.DynamicColors.dynamicBlack.color).withRenderingMode(.alwaysOriginal)
        case let .uiImage(uiImage, color):
            return uiImage.withTintColor(color ?? Asset.DynamicColors.dynamicBlack.color)
        }
    }
}

private struct RowItem: Hashable {
    private let id = UUID()
    let type: RowType
    let icon: RowIcon?
    let label: String
    let fontWeight: UIFont.Weight
    let textColor: UIColor?

    init(type: RowType, icon: RowIcon? = nil, label: String, fontWeight: UIFont.Weight = .regular, textColor: UIColor? = nil) {
        self.type = type
        self.icon = icon
        self.label = label
        self.fontWeight = fontWeight
        self.textColor = textColor
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RowItem, rhs: RowItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum ThemeStyleOption: String, CaseIterable, RawRepresentable {
    case auto = "自动"
    case light = "浅色"
    case dark = "深色"
}

private class MyUISwitch: UISwitch {
    var subscriptions: Set<AnyCancellable> = []

    convenience init(action: @escaping (Bool) -> Void, publisher: AnyPublisher<Bool, Never>) {
        self.init(frame: .zero, primaryAction: .init(handler: { uiAction in
            if let uiSwitch = uiAction.sender as? UISwitch {
                action(uiSwitch.isOn)
            }
        }))

        publisher.sink { [weak self] value in
            if let self = self {
                if self.isOn != value {
                    self.isOn = value
                    self.enumerateEventHandlers { action, _, _, _ in
                        if let action = action {
                            self.sendAction(action)
                        }
                    }
                }
            }
        }
        .store(in: &subscriptions)
    }
}

private class MyUISegmentedControl: UISegmentedControl {
    var subscriptions: Set<AnyCancellable> = []

    convenience init(actions: [UIAction], publisher: AnyPublisher<Int, Never>) {
        self.init(frame: .zero, actions: actions)

        publisher.sink { [weak self] value in
            if let self = self {
                if self.selectedSegmentIndex != value,
                   let action = self.actionForSegment(at: value) {
                    self.selectedSegmentIndex = value
                    self.sendAction(action)
                }
            }
        }
        .store(in: &subscriptions)
    }
}

private typealias DataSource = UICollectionViewDiffableDataSource<HeaderItem, ListItem>

class SettingViewController: UIViewController, HasNavigationPermission {
    private var modelObjects: [HeaderItem]!
    private var collectionView: UICollectionView!
    private lazy var dataSource = makeDataSource()
    private lazy var allDiscussionViewController = AllDiscussionsViewController()

    private static let iconImageSize: CGFloat = 24.0

    override func viewDidLoad() {
        super.viewDidLoad()
        setCollectionView()
        applyInitialSnapshots()
        title = ""
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    private func setCollectionView() {
        var listConfiguration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        listConfiguration.headerMode = .firstItemInSection
        listConfiguration.backgroundColor = .systemGroupedBackground
        let layout = UICollectionViewCompositionalLayout.list(using: listConfiguration)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        self.collectionView = collectionView
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func makeDataSource() -> DataSource {
        let headerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, HeaderItem> {
            cell, _, headerItem in
            var content = cell.defaultContentConfiguration()
            content.text = headerItem.title
            content.textProperties.color = Asset.DynamicColors.dynamicBlack.color
            content.textProperties.font = .rounded(ofSize: 20, weight: .bold)
            cell.contentConfiguration = content

            let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
            cell.accessories = [.outlineDisclosure(options: headerDisclosureOption)]
        }

        let itemNavigationCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, RowItem> {
            cell, _, item in
            var configuration = cell.defaultContentConfiguration()
            configuration.text = item.label
            configuration.textProperties.font = .rounded(ofSize: 17, weight: item.fontWeight)
            configuration.textProperties.color = item.textColor ?? Asset.DynamicColors.dynamicBlack.color
            if let icon = item.icon {
                configuration.image = icon.toUIImage()
                configuration.imageProperties.tintColor = .tintColor
                configuration.imageProperties.maximumSize = .init(width: Self.iconImageSize, height: Self.iconImageSize)
            }
            cell.contentConfiguration = configuration
            cell.accessories = [UICellAccessory.disclosureIndicator()]
        }

        let itemActionCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, RowItem> {
            cell, _, item in
            var configuration = cell.defaultContentConfiguration()
            configuration.text = item.label
            configuration.textProperties.font = .rounded(ofSize: 17, weight: item.fontWeight)
            configuration.textProperties.color = item.textColor ?? Asset.DynamicColors.dynamicBlack.color
            if let icon = item.icon {
                configuration.image = icon.toUIImage()
                configuration.imageProperties.tintColor = .tintColor
                configuration.imageProperties.maximumSize = .init(width: Self.iconImageSize, height: Self.iconImageSize)
            }
            cell.contentConfiguration = configuration
        }

        let itemToggleCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, RowItem> {
            cell, _, item in
            var configuration = cell.defaultContentConfiguration()
            configuration.text = item.label
            configuration.textProperties.font = .rounded(ofSize: 17, weight: item.fontWeight)
            configuration.textProperties.color = item.textColor ?? Asset.DynamicColors.dynamicBlack.color
            if let icon = item.icon {
                configuration.image = icon.toUIImage()
                configuration.imageProperties.tintColor = .tintColor
                configuration.imageProperties.maximumSize = .init(width: Self.iconImageSize, height: Self.iconImageSize)
            }
            if case let .toggle(action, publisher) = item.type {
                let switchView = MyUISwitch(action: action, publisher: publisher)
                cell.accessories = [.customView(configuration: .init(customView: switchView, placement: .trailing()))]
            }
            cell.contentConfiguration = configuration
        }

        let itemSegmentedControlCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, RowItem> {
            cell, _, item in
            var configuration = cell.defaultContentConfiguration()
            configuration.text = item.label
            configuration.textProperties.font = .rounded(ofSize: 17, weight: item.fontWeight)
            configuration.textProperties.color = item.textColor ?? Asset.DynamicColors.dynamicBlack.color
            if let icon = item.icon {
                configuration.image = icon.toUIImage()
                configuration.imageProperties.tintColor = .tintColor
                configuration.imageProperties.maximumSize = .init(width: Self.iconImageSize, height: Self.iconImageSize)
            }
            if case let .segmentedControl(actions, publisher) = item.type {
                let segmentedControl = MyUISegmentedControl(actions: actions, publisher: publisher)
                segmentedControl.sizeToFit()
                cell.accessories = [.customView(configuration: .init(customView: segmentedControl, placement: .trailing(), reservedLayoutWidth: .actual))]
            }
            cell.contentConfiguration = configuration
        }

        return DataSource(collectionView: collectionView) { collectionView, indexPath, listItem -> UICollectionViewCell? in
            var cell: UICollectionViewCell?
            switch listItem {
            case let .header(headerItem):
                cell = collectionView.dequeueConfiguredReusableCell(using: headerCellRegistration,
                                                                    for: indexPath,
                                                                    item: headerItem)

            case let .rowItem(item):
                switch item.type {
                case .navigation:
                    cell = collectionView.dequeueConfiguredReusableCell(using: itemNavigationCellRegistration,
                                                                        for: indexPath,
                                                                        item: item)

                case .action:
                    cell = collectionView.dequeueConfiguredReusableCell(using: itemActionCellRegistration,
                                                                        for: indexPath,
                                                                        item: item)

                case .toggle:
                    cell = collectionView.dequeueConfiguredReusableCell(using: itemToggleCellRegistration,
                                                                        for: indexPath,
                                                                        item: item)
                case .segmentedControl:
                    cell = collectionView.dequeueConfiguredReusableCell(using: itemSegmentedControlCellRegistration,
                                                                        for: indexPath,
                                                                        item: item)
                }
            }
            return cell
        }
    }

    private func applyInitialSnapshots() {
        modelObjects = [
            HeaderItem(title: "论坛", rowItems: [
                RowItem(type: .toggle(action: { value in
                                          AppGlobalState.shared.blockCompletely.send(value)
                                      },
                                      publisher: AppGlobalState.shared.blockCompletely.eraseToAnyPublisher()),
                        icon: .system(name: "person.crop.circle.badge.minus"), label: "完全隐藏屏蔽用户"),
                RowItem(type: .action(action: { sender in
                    if let url = URL(string: URLService.link(href: "https://ecnu.im/p/2-FAQ").url) {
                        UIApplication.shared.open(url)
                    }
                }), icon: .system(name: "questionmark.circle"), label: "论坛常见问题"),
                RowItem(type: .action(action: { sender in
                    if let url = URL(string: URLService.link(href: "https://ecnu.im/d/287").url) {
                        UIApplication.shared.open(url)
                    }
                }), icon: .system(name: "newspaper"), label: "论坛守则"),
                RowItem(type: .action(action: { sender in
                    if let url = URL(string: URLService.link(href: "https://discord.gg/a9NBjHwBEQ").url) {
                        UIApplication.shared.open(url)
                    }
                }), icon: .uiImage(uiImage: Asset.Icons.discord.image), label: "Discord 小组"),
                RowItem(type: .action(action: { sender in
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
                            .map { value -> Int in ThemeStyleOption.allCases.firstIndex(of: value)! }
                            .eraseToAnyPublisher()),
                        icon: .system(name: "moon.stars"),
                        label: "主题"),
            ]),
            HeaderItem(title: "小功能", rowItems: [
                RowItem(type: .action(action: { sender in
                    if let url = URL(string: URLService.link(href: "https://u-office.ecnu.edu.cn/xiaoli/").url) {
                        UIApplication.shared.open(url)
                    }
                }), icon: .system(name: "calendar"), label: "校历"),
                RowItem(type: .action(action: { sender in
                    if let url = URL(string: URLService.link(href: "http://www.ecard.ecnu.edu.cn/").url) {
                        UIApplication.shared.open(url)
                    }
                }), icon: .system(name: "creditcard"), label: "校园卡中心"),
                RowItem(type: .action(action: { sender in
                    Toast.default(icon: .emoji("👀"), title: "尚未支持").show()
                }), icon: .system(name: "calendar.badge.plus"), label: "导入课表至日历"),
            ]),
            HeaderItem(title: "其他", rowItems: [
                RowItem(type: .action(action: { sender in
                    if let url = URL(string: URLService.link(href: "https://github.com/JJAYCHEN1e/ecnu-im").url) {
                        UIApplication.shared.open(url)
                    }
                }), icon: .system(name: "chevron.left.forwardslash.chevron.right"), label: "GitHub 仓库"),
                RowItem(type: .action(action: { sender in
                    UIApplication.shared.presentOnTop(UIHostingController(rootView: AcknowledgementView()))
                }), icon: .system(name: "list.bullet.rectangle"), label: "致谢"),
            ]),
            HeaderItem(title: "账户", rowItems: [
                RowItem(type: .action(action: { sender in
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

        var dataSourceSnapshot = NSDiffableDataSourceSnapshot<HeaderItem, ListItem>()
        dataSourceSnapshot.appendSections(modelObjects)

        for headerItem in modelObjects {
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ListItem>()

            let headerListItem = ListItem.header(headerItem)
            sectionSnapshot.append([headerListItem])

            let sectionListItemArray = headerItem.rowItems.map { ListItem.rowItem($0) }
            sectionSnapshot.append(sectionListItemArray, to: headerListItem)

            sectionSnapshot.expand([headerListItem])
            dataSource.apply(sectionSnapshot, to: headerItem, animatingDifferences: false)
        }
    }
}

extension SettingViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let item = dataSource.itemIdentifier(for: indexPath) {
            if case let .rowItem(rowItem) = item {
                switch rowItem.type {
                case .toggle, .segmentedControl:
                    return false
                case .navigation, .action:
                    return true
                }
            }
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = dataSource.itemIdentifier(for: indexPath) {
            if case let .rowItem(rowItem) = item {
                switch rowItem.type {
                case let .navigation(action):
                    action()
                case let .action(action):
                    if let cell = collectionView.cellForItem(at: indexPath) {
                        action(cell)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        collectionView.deselectItem(at: indexPath, animated: true)
                    }
                case .toggle, .segmentedControl:
                    // This won't be selected.
                    collectionView.deselectItem(at: indexPath, animated: true)
                }
            }
        }
    }
}
