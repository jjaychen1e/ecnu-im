//
//  BackgroundColor.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/10.
//

import SwiftUI

struct BackgroundColor: ViewModifier {
    var opacity: Double = 0.6
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .overlay(
                Asset.SpecialColors.background.swiftUIColor
                    .opacity(colorScheme == .dark ? opacity : 0)
                    .blendMode(.overlay)
                    .allowsHitTesting(false)
            )
    }
}

extension View {
    func backgroundColor(opacity: Double = 0.6) -> some View {
        modifier(BackgroundColor(opacity: opacity))
    }
}
