//
//  TabBarContentView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/22.
//

import SwiftUI

struct TabItem {
    enum Tab {
        case posts
        case notifications
        case profile
        case setting
    }

    var tab: Tab
    var icon: String
    var name: String
    var color: Color
    var viewController: UIViewController
}

class TabBarViewModel2: ObservableObject {
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
    @State var selectedTab: TabItem.Tab
    @ObservedObject var viewModel: TabBarViewModel2

    init(viewModel: TabBarViewModel2) {
        self.viewModel = viewModel
        selectedTab = viewModel.tabBarItems[viewModel.selectedIndex].tab
        viewModel.selectAction(selectedTab)
    }

    var body: some View {
        HStack {
            content(totalWidth: viewModel.totalWidth)
        }
    }

    func content(totalWidth: CGFloat) -> some View {
        let tabCount = viewModel.tabBarItems.count
        let tabWidth = min(44, totalWidth / CGFloat(tabCount))
        return ForEach(Array(zip(viewModel.tabBarItems.indices, viewModel.tabBarItems)), id: \.0) { index, tabItem in
            if index == 0 { Spacer() }

            Button {
                selectedTab = tabItem.tab
                viewModel.selectAction(tabItem.tab)
            } label: {
                VStack(spacing: 0) {
                    Spacer()
                    Image(systemName: tabItem.icon)
                        .symbolVariant(.fill)
                        .font(.system(size: 17, weight: .bold))
                        .frame(width: 44, height: 29)
                    Text(tabItem.name).font(.caption2)
                        .frame(width: 88)
                        .lineLimit(1)
                }
            }
            .frame(width: tabWidth)
            .foregroundColor(selectedTab == tabItem.tab ? .primary : .secondary)

            Spacer()
        }
    }
}
