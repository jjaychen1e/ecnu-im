//
//  SwiftGen+SwiftUI+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/2.
//

import Foundation
import SwiftUI

extension ColorAsset {
    var swiftUIColor: SwiftUI.Color {
        SwiftUI.Color(uiColor: color)
    }
}
