//
//  DefaultTheme.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/2.
//

import Foundation
import SwiftUI

final class DefaultTheme: IMTheme {
    var textColor: Color = Asset.DynamicColors.dynamicWhite.swiftUIColor
    var backgroundColor1: Color = Asset.DefaultTheme.defaultThemeBackground1.swiftUIColor
    var backgroundColor2: Color = Asset.DefaultTheme.defaultThemeBackground2.swiftUIColor
    var cardColor: Color = Asset.DefaultTheme.defaultThemeCardColor.swiftUIColor
    var mentionColor: Color = Asset.DefaultTheme.defaultThemeMentionColor.swiftUIColor
    var linkTextColor: Color = Asset.DefaultTheme.defaultThemeLinkColor.swiftUIColor
    var primaryText: Color = Asset.DefaultTheme.defaultThemePrimaryText.swiftUIColor
    var secondaryText: Color = Asset.DefaultTheme.defaultThemeSecondaryText.swiftUIColor
}
