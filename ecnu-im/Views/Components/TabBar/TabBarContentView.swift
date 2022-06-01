//
//  TabBarContentView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/22.
//

import Combine
import SwiftUI

class TabItem {
    enum Tab {
        case home
        case notifications
        case profile
        case setting
    }

    var tab: Tab
    var icon: String
    var name: String
    var color: Color
    var viewController: UIViewController
    var secondaryViewControllers: [UIViewController]
    var badgeCount: Int = 0

    internal init(tab: TabItem.Tab, icon: String, name: String, color: Color, viewController: UIViewController, secondaryViewController: [UIViewController] = [], badgeCount: Int = 0) {
        self.tab = tab
        self.icon = icon
        self.name = name
        self.color = color
        self.viewController = viewController
        self.secondaryViewControllers = secondaryViewController
        self.badgeCount = badgeCount
    }
}

class TabBarViewModel: ObservableObject {
    @Published var totalWidth: CGFloat
    @Published var tabBarItems: [TabItem]
    @Published var selectedIndex: Int
    @Published var selectAction: (TabItem.Tab) -> Void

    init(totalWidth: CGFloat, tabBarItems: [TabItem], selectedIndex: Int, selectAction: @escaping (TabItem.Tab) -> Void) {
        self.totalWidth = totalWidth
        self.tabBarItems = tabBarItems
        self.selectedIndex = selectedIndex
        self.selectAction = selectAction
    }
}

struct TabBarContentView: View {
    private var selectedTab: TabItem.Tab {
        viewModel.tabBarItems[viewModel.selectedIndex].tab
    }

    @ObservedObject var viewModel: TabBarViewModel

    @State private var subscriptions: Set<AnyCancellable> = []

    init(viewModel: TabBarViewModel) {
        self.viewModel = viewModel
        viewModel.selectAction(selectedTab)
    }

    var body: some View {
        HStack {
            content(totalWidth: viewModel.totalWidth)
        }
        .onLoad {
            AppGlobalState.shared.$unreadNotificationCount.sink { change in
                viewModel.tabBarItems.first { item in
                    item.name == "通知"
                }?.badgeCount = change
                DispatchQueue.main.async {
                    viewModel.objectWillChange.send()
                }
            }.store(in: &subscriptions)
        }
    }

    func content(totalWidth: CGFloat) -> some View {
        let tabCount = viewModel.tabBarItems.count
        let tabWidth = min(44, totalWidth / CGFloat(tabCount))
        return ForEach(Array(zip(viewModel.tabBarItems.indices, viewModel.tabBarItems)), id: \.0) { index, tabItem in
            if index == 0 { Spacer(minLength: 0) }

            Button {
                viewModel.selectAction(tabItem.tab)
            } label: {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Image(systemName: tabItem.icon)
                        .symbolVariant(.fill)
                        .font(.system(size: 17, weight: .bold))
                        .frame(width: 44, height: 29)
                        .overlay(
                            Group {
                                if tabItem.badgeCount > 0 {
                                    Text("\(tabItem.badgeCount)")
                                        .padding(.all, 4)
                                        .foregroundColor(.white)
                                        .font(.system(size: 12))
                                        .background(
                                            Circle()
                                                .foregroundColor(.red)
                                        )
                                        .offset(x: 0, y: -3)
                                }
                            },
                            alignment: .topTrailing
                        )
                    Text(tabItem.name).font(.caption2)
                        .frame(width: 88)
                        .lineLimit(1)
                }
            }
            .frame(width: tabWidth)
            .foregroundColor(selectedTab == tabItem.tab ? .primary : .secondary)

            Spacer(minLength: 0)
        }
    }
}
