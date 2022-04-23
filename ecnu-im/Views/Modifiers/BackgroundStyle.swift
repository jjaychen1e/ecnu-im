//
//  BackgroundStyle.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/10.
//

import SwiftUI

struct BackgroundStyle: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.6
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .backgroundColor(opacity: opacity)
            .cornerRadius(cornerRadius)
            .shadow(color: Color("Shadow").opacity(colorScheme == .dark ? 0.3 : 0), radius: 20, x: 0, y: 10)
            .modifier(OutlineOverlay(cornerRadius: cornerRadius))
    }
}

extension View {
    func backgroundStyle(cornerRadius: CGFloat = 20, opacity: Double = 0.6) -> some View {
        modifier(BackgroundStyle(cornerRadius: cornerRadius, opacity: opacity))
    }
}
