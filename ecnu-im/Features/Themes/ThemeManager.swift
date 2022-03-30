//
//  ThemeManager.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/2.
//

import Foundation

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published private(set) var theme: Theme = DefaultTheme()

    public func applyTheme(theme: Theme) {
        self.theme = theme
    }
}
