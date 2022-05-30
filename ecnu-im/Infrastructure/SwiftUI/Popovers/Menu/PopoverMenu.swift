//
//  PopoverMenu.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/17.
//

import SwiftUI

struct PopoverMenuItem: View {
    @State var title: String
    @State var systemImage: String
    @State var titleColor: Color = .primary
    @State var iconColor: Color = .primary
    @State var action: () -> Void

    @Environment(\.operatePopoverMenu) var operatePopoverMenu
    @Environment(\.popoverMenuMinWidth) var popoverMenuMinWidth

    @Environment(\.isEnabled) var isEnabled

    var body: some View {
        Button {
            operatePopoverMenu(false, action)
        } label: {
            HStack {
                Image(systemName: systemImage)
                    .frame(width: 25, height: 25)
                    .foregroundColor(isEnabled ? iconColor : nil)
                Text(title)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(isEnabled ? titleColor : nil)
            }
            .frame(minWidth: popoverMenuMinWidth, alignment: .leading)
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .overlay(
            Color.primary.opacity(0.1).frame(height: 1).frame(maxWidth: .infinity),
            alignment: .bottom
        )
    }
}

private struct _PopoverMenu<Label>: View where Label: View {
    private let label: () -> Label

    @Environment(\.operatePopoverMenu) var operatePopoverMenu

    init(@ViewBuilder label: @escaping () -> Label) {
        self.label = label
    }

    var body: some View {
        Button {
            operatePopoverMenu(true) {}
        } label: {
            label()
                .frame(minWidth: 24, minHeight: 24)
                .background(Color.primary.opacity(0.0001))
        }
    }
}

struct PopoverMenu<Label, Content>: View where Label: View, Content: View {
    private let content: () -> Content
    private let label: () -> Label

    @State var minWidth: CGFloat = 180

    init(@ViewBuilder content: @escaping () -> Content, @ViewBuilder label: @escaping () -> Label) {
        self.content = content
        self.label = label
    }

    var body: some View {
        _PopoverMenu(label: label)
            .alwaysPopover {
                VStack(alignment: .leading, spacing: 0) {
                    content()
                        .environment(\.popoverMenuMinWidth, minWidth)
                }
                .overlay(
                    Color(uiColor: UIColor.systemBackground).frame(height: 1).frame(maxWidth: .infinity),
                    alignment: .top
                )
                .overlay(
                    Color(uiColor: UIColor.systemBackground).frame(height: 1).frame(maxWidth: .infinity),
                    alignment: .bottom
                )
            }
    }
}

struct OperatePopoverMenuKey: EnvironmentKey {
    static let defaultValue: (_ present: Bool, _ completion: @escaping () -> Void) -> Void = { _, _ in }
}

extension EnvironmentValues {
    var operatePopoverMenu: (_ present: Bool, _ completion: @escaping () -> Void) -> Void {
        get { self[OperatePopoverMenuKey.self] }
        set { self[OperatePopoverMenuKey.self] = newValue }
    }
}

private struct PopoverMenuMinWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0.0
}

private extension EnvironmentValues {
    var popoverMenuMinWidth: CGFloat {
        get { self[PopoverMenuMinWidthKey.self] }
        set { self[PopoverMenuMinWidthKey.self] = newValue }
    }
}
