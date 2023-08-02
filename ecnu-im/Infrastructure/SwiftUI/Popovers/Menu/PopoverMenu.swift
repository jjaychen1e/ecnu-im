//
//  PopoverMenu.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/17.
//

import SwiftUI

struct PopoverMenuLabelItem: View {
    @State var title: String
    @State var systemImage: String
    @State var titleColor: Color = .primary
    @State var iconColor: Color = .primary
    @State var action: () -> Void

    @Environment(\.popoverMenuDismissEnvironment) var popoverMenuDismissEnvironment
    @Environment(\.popoverMenuMinWidth) var popoverMenuMinWidth

    @Environment(\.isEnabled) var isEnabled

    var body: some View {
        Button {
            popoverMenuDismissEnvironment.operator?.dismiss(action)
        } label: {
            HStack {
                Image(systemName: systemImage)
                    .frame(width: 25, height: 25)
                    .foregroundColor(isEnabled ? iconColor : .primary.opacity(0.15))
                Text(title)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(isEnabled ? titleColor : .primary.opacity(0.15))
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

struct PopoverMenuCustomItem<Content>: View where Content: View {
    private let content: () -> Content

    @Environment(\.popoverMenuMinWidth) var popoverMenuMinWidth
    @Environment(\.isEnabled) var isEnabled

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .frame(minWidth: popoverMenuMinWidth, alignment: .leading)
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

    @Environment(\.popoverMenuPresentEnvironment) var popoverMenuPresentEnvironment

    init(@ViewBuilder label: @escaping () -> Label) {
        self.label = label
    }

    var body: some View {
        Button {
            popoverMenuPresentEnvironment.operator?.present()
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
                .fixedSize(horizontal: true, vertical: false)
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

class PopoverMenuPresentEnvironmentOperator {
    var present: () -> Void

    init(_ present: @escaping () -> Void) {
        self.present = present
    }
}

class PopoverMenuPresentEnvironment {
    init(operator: PopoverMenuPresentEnvironmentOperator? = nil) {
        self.operator = `operator`
    }

    weak var `operator`: PopoverMenuPresentEnvironmentOperator?
}

class PopoverMenuDismissEnvironmentOperator {
    var dismiss: (@escaping () -> Void) -> Void

    init(_ dismiss: @escaping (@escaping () -> Void) -> Void) {
        self.dismiss = dismiss
    }
}

class PopoverMenuDismissEnvironment {
    init(operator: PopoverMenuDismissEnvironmentOperator? = nil) {
        self.operator = `operator`
    }

    weak var `operator`: PopoverMenuDismissEnvironmentOperator?
}

struct OperatePopoverPresentMenuKey: EnvironmentKey {
    static let defaultValue: PopoverMenuPresentEnvironment = .init()
}

struct OperatePopoverDismissMenuKey: EnvironmentKey {
    static let defaultValue: PopoverMenuDismissEnvironment = .init()
}

extension EnvironmentValues {
    var popoverMenuPresentEnvironment: PopoverMenuPresentEnvironment {
        get { self[OperatePopoverPresentMenuKey.self] }
        set { self[OperatePopoverPresentMenuKey.self] = newValue }
    }
}

extension EnvironmentValues {
    var popoverMenuDismissEnvironment: PopoverMenuDismissEnvironment {
        get { self[OperatePopoverDismissMenuKey.self] }
        set { self[OperatePopoverDismissMenuKey.self] = newValue }
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
