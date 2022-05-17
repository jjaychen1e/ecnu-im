//
//  AlwaysPopoverModifier.swift
//  Popovers
//
//  Created by 陈俊杰 on 2022/5/17.
//
// Based on: https://pspdfkit.com/blog/2022/presenting-popovers-on-iphone-with-swiftui/
//

import SwiftUI

private class AlwaysPopoverModifierViewModel: ObservableObject {
    weak var presentedViewController: UIViewController?
}

private struct AlwaysPopoverModifier<PopoverContent>: ViewModifier where PopoverContent: View {
    let contentBlock: () -> PopoverContent

    @StateObject private var viewModel = AlwaysPopoverModifierViewModel()

    // Workaround for missing @StateObject in iOS 13.
    private struct Store {
        var anchorView = UIView()
    }

    @State private var store = Store()

    init(contentBlock: @escaping () -> PopoverContent) {
        self.contentBlock = contentBlock
    }

    func body(content: Content) -> some View {
        return content
            .background(InternalAnchorView(uiView: store.anchorView))
            .environment(\.operatePopoverMenu) { present, completion in
                operatePopoverContent(present, completion)
            }
    }

    private func operatePopoverContent(_ present: Bool, _ completion: @escaping () -> Void) {
        if present {
            presentPopover(completion: completion)
        } else {
            viewModel.presentedViewController?.dismiss(animated: true, completion: completion)
            viewModel.presentedViewController = nil
        }
    }

    private func presentPopover(completion: @escaping () -> Void) {
        let contentController = ContentViewController(rootView: contentBlock()
            .environment(\.operatePopoverMenu) { present, completion in
                operatePopoverContent(present, completion)
            })
        contentController.modalPresentationStyle = .popover

        let view = store.anchorView
        guard let popover = contentController.popoverPresentationController else { return }
        popover.sourceView = view
        popover.sourceRect = view.bounds
        popover.delegate = contentController

        guard let sourceVC = view.closestVC() else { return }
        if let presentedVC = sourceVC.presentedViewController {
            presentedVC.dismiss(animated: true) {
                sourceVC.present(contentController, animated: true, completion: completion)
                viewModel.presentedViewController = sourceVC
            }
        } else {
            sourceVC.present(contentController, animated: true, completion: completion)
            viewModel.presentedViewController = sourceVC
        }
    }

    private struct InternalAnchorView: UIViewRepresentable {
        typealias UIViewType = UIView
        let uiView: UIView

        func makeUIView(context: Self.Context) -> Self.UIViewType {
            uiView
        }

        func updateUIView(_ uiView: Self.UIViewType, context: Self.Context) {}
    }
}

public extension View {
    func alwaysPopover<Content>(@ViewBuilder content: @escaping () -> Content) -> some View where Content: View {
        modifier(AlwaysPopoverModifier(contentBlock: content))
    }
}

private extension UIView {
    func closestVC() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let vc = responder as? UIViewController {
                if vc.parent != nil || vc.presentingViewController != nil {
                    return vc
                }
            }
            responder = responder?.next
        }
        return nil
    }
}
