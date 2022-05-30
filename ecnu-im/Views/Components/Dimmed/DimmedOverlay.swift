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
    @ObservedObject var appGlobalState = AppGlobalState.shared

    var opacity: CGFloat {
        if !isHidden, !ignored {
            return 1.0
        }

        if ignored, appGlobalState.blockCompletely.value {
            return 0.0
        }
        
        return 0.3
    }

    func body(content: Content) -> some View {
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
            .opacity(opacity)
            .overlay(
                Text(overlayText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            )
    }
}

extension View {
    func dimmedOverlay(ignored: Binding<Bool>, isHidden: Binding<Bool>) -> some View {
        modifier(DimmedOverlay(ignored: ignored, isHidden: isHidden))
    }
}
