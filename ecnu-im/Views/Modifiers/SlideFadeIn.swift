//
//  SlideFadeIn.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/10.
//

import SwiftUI

struct SlideFadeIn: ViewModifier {
    var show: Bool
    var offset: Double

    func body(content: Content) -> some View {
        content
            .opacity(show ? 1 : 0)
            .offset(y: show ? 0 : offset)
    }
}

extension View {
    func slideFadeIn(show: Bool, offset: Double = 10) -> some View {
        modifier(SlideFadeIn(show: show, offset: offset))
    }
}
