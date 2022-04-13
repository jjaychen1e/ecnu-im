//
//  ThemeManager.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/2.
//

import Foundation

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published private(set) var theme: IMTheme = DefaultTheme()

    public func applyTheme(theme: IMTheme) {
        self.theme = theme
    }
}
