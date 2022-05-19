//
//  Color+Dynamic.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/19.
//

import SwiftUI

extension Color {
    init(
        light lightModeColor: @escaping @autoclosure () -> Color,
        dark darkModeColor: @escaping @autoclosure () -> Color
    ) {
        self.init(UIColor(
            light: UIColor(lightModeColor()),
            dark: UIColor(darkModeColor())
        ))
    }
}
