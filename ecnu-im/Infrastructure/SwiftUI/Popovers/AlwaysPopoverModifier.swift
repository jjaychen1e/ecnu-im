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
    func dismiss(_ completion: @escaping () -> Void) {
        presentedViewController?.dismiss(animated: true, completion: completion)
        presentedViewController = nil
    }
}

private class AnchorViewModel: ObservableObject {
    var anchorView = UIView()
}

class PopoverOperatorViewModel: ObservableObject {
    var popoverMenuPresentEnvironmentOperator: PopoverMenuPresentEnvironmentOperator = .init {}
    var popoverMenuDismissEnvironmentOperator: PopoverMenuDismissEnvironmentOperator = .init { _ in }
}

private struct AlwaysPopoverModifier<PopoverContent>: ViewModifier where PopoverContent: View {
    @State var contentBlock: () -> PopoverContent

    @StateObject private var viewModel = AlwaysPopoverModifierViewModel()
    @StateObject private var anchorViewModel = AnchorViewModel()
    @StateObject private var popoverOperatorViewModel = PopoverOperatorViewModel()

    init(contentBlock: @escaping () -> PopoverContent) {
        self.contentBlock = contentBlock
    }

    func body(content: Content) -> some View {
        return content
            .background(InternalAnchorView(uiView: anchorViewModel.anchorView))
            .environment(\.popoverMenuPresentEnvironment, .init(operator: popoverOperatorViewModel.popoverMenuPresentEnvironmentOperator))
            .onLoad(perform: {
                // Damn it.. memory leak
                let content = contentBlock()
                    .environment(\.popoverMenuDismissEnvironment, .init(operator: popoverOperatorViewModel.popoverMenuDismissEnvironmentOperator))
                popoverOperatorViewModel.popoverMenuPresentEnvironmentOperator.present = { [weak viewModel, weak anchorViewModel] in
                    if let viewModel = viewModel, let anchorViewModel = anchorViewModel {
                        let contentController = ContentViewController(rootView: content)
                        contentController.modalPresentationStyle = .popover

                        let view = anchorViewModel.anchorView
                        guard let popover = contentController.popoverPresentationController else { return }
                        popover.sourceView = view
                        popover.sourceRect = view.bounds
                        popover.delegate = contentController

                        guard let sourceVC = view.closestVC() else { return }
                        if let presentedVC = sourceVC.presentedViewController {
                            presentedVC.dismiss(animated: true) {
                                sourceVC.present(contentController, animated: true, completion: {})
                                viewModel.presentedViewController = sourceVC
                            }
                        } else {
                            sourceVC.present(contentController, animated: true, completion: {})
                            viewModel.presentedViewController = sourceVC
                        }
                    }
                }
                popoverOperatorViewModel.popoverMenuDismissEnvironmentOperator.dismiss = { [weak viewModel] completion in
                    viewModel?.dismiss(completion)
                }
            })
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
