//
//  DefaultTheme.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/2.
//

import Foundation
import SwiftUI

final class DefaultTheme: Theme {
    var textColor: Color = Asset.dynamicWhite.swiftUIColor
    var backgroundColor1: Color = Asset.defaultThemeBackground1.swiftUIColor
    var backgroundColor2: Color = Asset.defaultThemeBackground2.swiftUIColor
    var cardColor: Color = Asset.defaultThemeCardColor.swiftUIColor
    var mentionColor: Color = Asset.defaultThemeMentionColor.swiftUIColor
    var linkTextColor: Color = Asset.defaultThemeLinkColor.swiftUIColor
    var primaryText: Color = Asset.defaultThemePrimaryText.swiftUIColor
    var secondaryText: Color = Asset.defaultThemeSecondaryText.swiftUIColor
}
