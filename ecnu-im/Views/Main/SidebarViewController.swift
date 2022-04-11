//
//  SidebarViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/3.
//

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
    case action(textColor: UIColor? = nil, action: (_ sender: UIView) -> Void)
    case toggle(action: (Bool) -> Void)
    case segmentedControl(actions: [UIAction])
}

private enum RowIcon {
    case system(name: String)
    case uiImage(uiImage: UIImage)
    case image(name: String)

    // TODO: drop down, segmented control

    func toUIImage() -> UIImage? {
        switch self {
        case let .image(name):
            return UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
        case let .system(name):
            return UIImage(systemName: name)?.withRenderingMode(.alwaysTemplate)
        case let .uiImage(uiImage):
            return uiImage.withRenderingMode(.alwaysTemplate)
        }
    }
}

private struct RowItem: Hashable {
    private let id = UUID()
    let type: RowType
    let icon: RowIcon?
    let label: String

    init(type: RowType, icon: RowIcon? = nil, label: String) {
        self.type = type
        self.icon = icon
        self.label = label
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RowItem, rhs: RowItem) -> Bool {
        lhs.id == rhs.id
    }
}

private enum ThemeOption: String, CaseIterable {
    case auto = "自动"
    case light = "浅色"
    case dark = "深色"
}

private typealias DataSource = UICollectionViewDiffableDataSource<HeaderItem, ListItem>

class SidebarViewController: UIViewController {
    private var modelObjects: [HeaderItem]!
    private var collectionView: UICollectionView!
    private lazy var dataSource = makeDataSource()
    private lazy var allDiscussionViewController = AllDiscussionsViewController()

    private static let iconImageSize: CGFloat = 24.0

    override func viewDidLoad() {
        super.viewDidLoad()
        setCollectionView()
        applyInitialSnapshots()
        selectDefaultCell()
        title = ""
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    func selectDefaultCell() {
        if let indexPath = dataSource.indexPath(for: ListItem.rowItem(modelObjects[0].rowItems[0])) {
            collectionView.selectItem(at: .init(row: 1, section: 0), animated: true, scrollPosition: .top)
            if let item = dataSource.itemIdentifier(for: indexPath) {
                if case let .rowItem(rowItem) = item, case let .navigation(action) = rowItem.type {
                    action()
                }
            }
        }
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
            content.textProperties.font = .systemFont(ofSize: 20, weight: .bold)
            cell.contentConfiguration = content

            let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
            cell.accessories = [.outlineDisclosure(options: headerDisclosureOption)]
        }

        let itemNavigationCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, RowItem> {
            cell, _, item in
            var configuration = cell.defaultContentConfiguration()
            configuration.text = item.label
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
            if case let .action(textColor, _) = item.type, let textColor = textColor {
                configuration.textProperties.color = textColor
            } else {
                configuration.textProperties.color = .tintColor
            }
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
            if let icon = item.icon {
                configuration.image = icon.toUIImage()
                configuration.imageProperties.tintColor = .tintColor
                configuration.imageProperties.maximumSize = .init(width: Self.iconImageSize, height: Self.iconImageSize)
            }
            let switchView = UISwitch(frame: .zero, primaryAction: .init(handler: { action in
                if let uiSwitch = action.sender as? UISwitch {
                    if case let .toggle(action) = item.type {
                        action(uiSwitch.isOn)
                    }
                }
            }))
            cell.accessories = [.customView(configuration: .init(customView: switchView, placement: .trailing()))]
            cell.contentConfiguration = configuration
        }

        let itemSegmentedControlCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, RowItem> {
            cell, _, item in
            var configuration = cell.defaultContentConfiguration()
            configuration.text = item.label
            if let icon = item.icon {
                configuration.image = icon.toUIImage()
                configuration.imageProperties.tintColor = .tintColor
                configuration.imageProperties.maximumSize = .init(width: Self.iconImageSize, height: Self.iconImageSize)
            }
            if case let .segmentedControl(actions) = item.type {
                let segmentedControl: UISegmentedControl = .init(
                    frame: .zero,
                    actions: actions
                )
                segmentedControl.selectedSegmentIndex = 0
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
            HeaderItem(title: "讨论", rowItems: [
                RowItem(type: .navigation(action: {
                    self.splitViewController?.setSplitViewRoot(viewController: self.allDiscussionViewController,
                                                               column: .supplementary,
                                                               immediatelyShow: true)
                }),
                icon: .system(name: "text.bubble"),
                label: "最新话题"),
            ]),
            HeaderItem(title: "通知中心", rowItems: [
                RowItem(type: .navigation(action: {
                    self.splitViewController?.setSplitViewRoot(viewController: UIHostingController(rootView: Text("未读通知")),
                                                               column: .supplementary,
                                                               immediatelyShow: true)
                }),
                icon: .system(name: "bell.badge"),
                label: "未读通知"),
                RowItem(type: .navigation(action: {
                    self.splitViewController?.setSplitViewRoot(viewController: UIHostingController(rootView: Text("所有通知")),
                                                               column: .supplementary,
                                                               immediatelyShow: true)

                }),
                icon: .system(name: "bell"),
                label: "所有通知"),
            ]),
            HeaderItem(title: "账户", rowItems: [
                RowItem(type: .navigation(action: { self.splitViewController?.setSplitViewRoot(viewController: UIHostingController(rootView: Text("个人资料")),
                                                                                               column: .supplementary,
                                                                                               immediatelyShow: true) }),
                icon: .system(name: "person.crop.circle"),
                label: "个人资料"),
                RowItem(type: .action(textColor: .systemRed,
                                      action: { sender in
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
                        label: "退出登录"),
            ]),
            HeaderItem(title: "设置", rowItems: [
                RowItem(type: .toggle(action: { isOn in
                    print(isOn)
                }),
                icon: .system(name: "gearshape"),
                label: "开关例子"),
                RowItem(type: .segmentedControl(actions: ThemeOption.allCases.map { option in
                    UIAction(title: option.rawValue) { _ in
                        switch option {
                        case .auto:
                            UIApplication.shared.sceneWindows.forEach { window in
                                window.overrideUserInterfaceStyle = .unspecified
                            }
                        case .light:
                            UIApplication.shared.sceneWindows.forEach { window in
                                window.overrideUserInterfaceStyle = .light
                            }
                        case .dark:
                            UIApplication.shared.sceneWindows.forEach { window in
                                window.overrideUserInterfaceStyle = .dark
                            }
                        }
                    }
                }),
                icon: .uiImage(uiImage: Asset.Icons.darkTheme.image),
                label: "主题颜色"),
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

extension SidebarViewController: UICollectionViewDelegate {
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
                case let .action(_, action):
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
