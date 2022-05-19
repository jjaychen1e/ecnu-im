//
//  DimmedOverlay.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/19.
//

import SwiftUI

private struct DimmedOverlay: ViewModifier {
    @Binding var ignored: Bool
    @Binding var isHidden: Bool

    func body(content: Content) -> some View {
        let isDimmed = isHidden || ignored
        let color: Color = ignored ? .red : .primary.opacity(0.7)
        let overlayText: String = {
            var overlayTexts: [String] = []
            if isHidden {
                overlayTexts.append("已隐藏")
            }
            if ignored {
                overlayTexts.append("已屏蔽")
            }
            return overlayTexts.joined(separator: ", ")
        }()
        content
            .opacity(isDimmed ? 0.3 : 1.0)
            .overlay(
                Text(overlayText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            )
    }
}

extension View {
    func dimmedOverlay(ignored: Binding<Bool>, isHidden: Binding<Bool>) -> some View {
        self.modifier(DimmedOverlay(ignored: ignored, isHidden: isHidden))
    }
}
