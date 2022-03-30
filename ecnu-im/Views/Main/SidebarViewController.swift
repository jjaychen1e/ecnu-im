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

private struct RowItem: Hashable, Equatable {
    private let id = UUID()
    let action: () -> Void
    let icon: String
    let label: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RowItem, rhs: RowItem) -> Bool {
        lhs.id == rhs.id
    }
}

private typealias DataSource = UICollectionViewDiffableDataSource<HeaderItem, ListItem>

class SidebarViewController: UIViewController {
    private var modelObjects: [HeaderItem]!
    private var collectionView: UICollectionView!
    private lazy var dataSource = makeDataSource()
    private lazy var allDiscussionViewController = AllDiscussionsViewController()

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
                if case let .rowItem(rowItem) = item {
                    rowItem.action()
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
            content.textProperties.color = Asset.dynamicBlack.color
            content.textProperties.font = .systemFont(ofSize: 20, weight: .bold)
            cell.contentConfiguration = content

            let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
            cell.accessories = [.outlineDisclosure(options: headerDisclosureOption)]
        }

        let itemCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, RowItem> {
            cell, _, item in
            var configuration = cell.defaultContentConfiguration()
            configuration.text = item.label
            configuration.image = UIImage(systemName: item.icon)
            cell.contentConfiguration = configuration
            cell.accessories = [UICellAccessory.disclosureIndicator()]
        }

        return DataSource(collectionView: collectionView) { collectionView, indexPath, listItem -> UICollectionViewCell? in
            switch listItem {
            case let .header(headerItem):
                let cell = collectionView.dequeueConfiguredReusableCell(using: headerCellRegistration,
                                                                        for: indexPath,
                                                                        item: headerItem)
                return cell
            case let .rowItem(item):
                let cell = collectionView.dequeueConfiguredReusableCell(using: itemCellRegistration,
                                                                        for: indexPath,
                                                                        item: item)
                return cell
            }
        }
    }

    private func applyInitialSnapshots() {
        modelObjects = [
            HeaderItem(title: "讨论", rowItems: [
                RowItem(action: {
                    self.splitViewController?.setSplitViewRoot(viewController: self.allDiscussionViewController, column: .supplementary, immediatelyShow: true)
                }, icon: "wand.and.stars", label: "最新话题"),
                RowItem(action: {}, icon: "wand.and.stars", label: "最新回复"),
            ]),
            HeaderItem(title: "设置", rowItems: [
                RowItem(action: {
                    self.splitViewController?.setSplitViewRoot(viewController: UIHostingController(rootView: Text("Setting View")), column: .supplementary, immediatelyShow: true)
                }, icon: "wand.and.stars", label: "最新话题"),
                RowItem(action: { print("Clicked 4") }, icon: "wand.and.stars", label: "最新回复"),
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
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = dataSource.itemIdentifier(for: indexPath) {
            if case let .rowItem(rowItem) = item {
                rowItem.action()
            }
        }
    }
}
