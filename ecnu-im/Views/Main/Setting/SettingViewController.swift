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

enum ListItem: Hashable {
    case header(HeaderItem)
    case rowItem(RowItem)
}

// Header cell data type
struct HeaderItem: Hashable {
    let title: String
    let rowItems: [RowItem]
    let type: HeaderType

    init(title: String, rowItems: [RowItem], type: HeaderType = .collapsible) {
        self.title = title
        self.rowItems = rowItems
        self.type = type
    }

    static func collapsible(title: String, rowItems: [RowItem]) -> HeaderItem {
        HeaderItem(title: title, rowItems: rowItems, type: .collapsible)
    }

    static func normal(title: String, rowItems: [RowItem]) -> HeaderItem {
        HeaderItem(title: title, rowItems: rowItems, type: .normal)
    }
}

enum HeaderType {
    case normal
    case collapsible
}

enum RowType {
    case navigation(action: () -> Void)
    case action(action: (_ sender: UIView) -> Void)
    case toggle(action: (Bool) -> Void, publisher: AnyPublisher<Bool, Never>)
    case segmentedControl(actions: [UIAction], publisher: AnyPublisher<Int, Never>)

    // TODO: drop down
}

enum RowIcon {
    case system(name: String, color: UIColor? = nil)
    case uiImage(uiImage: UIImage, color: UIColor? = Asset.DynamicColors.dynamicBlack.color)
    case image(name: String, color: UIColor? = nil)

    func toUIImage() -> UIImage? {
        switch self {
        case let .image(name, color):
            return UIImage(named: name)?.withTintColor(color ?? Asset.DynamicColors.dynamicBlack.color).withRenderingMode(.alwaysOriginal)
        case let .system(name, color):
            return UIImage(systemName: name)?.withTintColor(color ?? Asset.DynamicColors.dynamicBlack.color).withRenderingMode(.alwaysOriginal)
        case let .uiImage(uiImage, color):
            if let color = color {
                return uiImage.withTintColor(color)
            } else {
                return uiImage
            }
        }
    }
}

struct RowItem: Hashable {
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
                    self.setOn(value, animated: true)
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
    var modelObjects: [HeaderItem] = []
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
        let collapsibleHeaderCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, HeaderItem> {
            cell, _, headerItem in
            var content = cell.defaultContentConfiguration()
            content.text = headerItem.title
            content.textProperties.color = Asset.DynamicColors.dynamicBlack.color
            content.textProperties.font = .rounded(ofSize: 20, weight: .bold)
            cell.contentConfiguration = content

            let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
            cell.accessories = [.outlineDisclosure(options: headerDisclosureOption)]
        }

        let normalHeaderCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, HeaderItem> {
            cell, _, headerItem in
            var content = cell.defaultContentConfiguration()
            content.text = headerItem.title
            content.textProperties.color = Asset.DynamicColors.dynamicBlack.color
            content.textProperties.font = .rounded(ofSize: 20, weight: .bold)
            cell.contentConfiguration = content
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
                switch headerItem.type {
                case .collapsible:
                    cell = collectionView.dequeueConfiguredReusableCell(using: collapsibleHeaderCellRegistration,
                                                                        for: indexPath,
                                                                        item: headerItem)

                case .normal:
                    cell = collectionView.dequeueConfiguredReusableCell(using: normalHeaderCellRegistration,
                                                                        for: indexPath,
                                                                        item: headerItem)
                }
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

    func applyInitialSnapshots() {
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        collectionView.deselectItem(at: indexPath, animated: true)
                    }
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
