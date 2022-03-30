//
//  UISplitViewController+Helper+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/3.
//

import Foundation
import SwiftUI
import UIKit

private final class WeakBox<A: AnyObject> {
    weak var unbox: A?
    init(_ value: A) {
        unbox = value
    }
}

private struct WeakArray<Element: AnyObject> {
    private var items: [WeakBox<Element>] = []

    init(_ elements: [Element]) {
        items = elements.map { WeakBox($0) }
    }

    mutating func append(_ element: Element) {
        items.append(WeakBox(element))
    }

    mutating func clearNilElements() {
        items = items.filter { $0.unbox != nil }
    }
}

extension WeakArray: Collection {
    var startIndex: Int { return items.startIndex }
    var endIndex: Int { return items.endIndex }

    subscript(_ index: Int) -> Element? {
        return items[index].unbox
    }

    func index(after idx: Int) -> Int {
        return items.index(after: idx)
    }
}

private var configuredViewControllersAssociatedKey: Void?
private var horizontalSizeClassObservationsAssociatedKey: Void?
extension UISplitViewController {
    private var configuredViewControllers: WeakArray<UIViewController>? {
        get {
            return objc_getAssociatedObject(self, &configuredViewControllersAssociatedKey) as? WeakArray<UIViewController>
        }
        set {
            objc_setAssociatedObject(self, &configuredViewControllersAssociatedKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    class HorizontalSizeClassObservation {
        var enter: (() -> Void)?
        var exit: (() -> Void)?

        internal init(enter: @escaping () -> Void, exit: @escaping () -> Void) {
            self.enter = enter
            self.exit = exit
        }
    }

    private var horizontalSizeClassObservations: WeakArray<HorizontalSizeClassObservation>? {
        get {
            return objc_getAssociatedObject(self, &horizontalSizeClassObservationsAssociatedKey) as? WeakArray<HorizontalSizeClassObservation>
        }
        set {
            objc_setAssociatedObject(self, &horizontalSizeClassObservationsAssociatedKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // TODO: This never trigger...
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animateAlongsideTransition(in: nil) { _ in
            if let horizontalSizeClassObservations = self.horizontalSizeClassObservations {
                if self.traitCollection.horizontalSizeClass == .compact {
                    for observation in horizontalSizeClassObservations {
                        observation?.enter?()
                    }
                } else {
                    for observation in horizontalSizeClassObservations {
                        observation?.exit?()
                    }
                }
            }
        }
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // TODO: This never trigger...
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            if let horizontalSizeClassObservations = horizontalSizeClassObservations {
                if traitCollection.horizontalSizeClass == .compact {
                    for observation in horizontalSizeClassObservations {
                        observation?.enter?()
                    }
                } else {
                    for observation in horizontalSizeClassObservations {
                        observation?.exit?()
                    }
                }
            }
        }
    }

    func setSplitViewRoot<Content: View>(view: Content, column: UISplitViewController.Column, immediatelyShow: Bool = false, animated: Bool = false) {
        let hostingViewController = UIHostingController(rootView:
            view
                .environment(\.splitVC, self)
                .environment(\.nvc, viewController(for: column) as? UINavigationController)
        )
        setSplitViewRoot(viewController: hostingViewController, column: column, immediatelyShow: immediatelyShow, animated: animated)
    }

    func setSplitViewRoot(viewController: UIViewController, column: UISplitViewController.Column, immediatelyShow: Bool = false, animated: Bool = false) {
        if let nvc = self.viewController(for: column) as? UINavigationController {
            if configuredViewControllers == nil || !configuredViewControllers!.contains(viewController) {
                // TODO: When app is going to compact mode, this should change as well...
                if configuredViewControllers == nil {
                    configuredViewControllers = WeakArray<UIViewController>([])
                }
                configuredViewControllers!.append(viewController)
                configuredViewControllers!.clearNilElements()

                if column == .supplementary {
                    let barButtonItem = UIBarButtonItem.supplementaryToggleSidebarBarButtonItem(splitViewController: self)
                    let enterCompactAction = { [weak barButtonItem] in
                        // TODO: Can I remove this?
                        viewController.navigationItem.setHidesBackButton(true, animated: false)
                        if let barButtonItem = barButtonItem {
                            viewController.navigationItem.prependLeftBarButtonItems(barButtonItem)
                        }
                    }

                    let exitCompactAction = { [weak barButtonItem] in
                        viewController.navigationItem.setHidesBackButton(false, animated: false)
                        if let barButtonItem = barButtonItem {
                            if let index = viewController.navigationItem.leftBarButtonItems?.firstIndex(of: barButtonItem) {
                                viewController.navigationItem.leftBarButtonItems?.remove(at: index)
                            }
                        }
                    }

                    if traitCollection.horizontalSizeClass == .compact {
                        enterCompactAction()
                    }

                    if horizontalSizeClassObservations == nil {
                        horizontalSizeClassObservations = WeakArray<HorizontalSizeClassObservation>([])
                    }
                    horizontalSizeClassObservations!.append(.init(enter: enterCompactAction, exit: exitCompactAction))
                } else if column == .primary {
                    viewController.navigationItem.prependLeftBarButtonItems(.primaryToggleSidebarBarButtonItem(splitViewController: self))
                } else if column == .secondary {
//                    let appearance = UINavigationBarAppearance()
//                    appearance.shadowColor = nil
//                    appearance.configureWithTransparentBackground()
//                    viewController.navigationItem.scrollEdgeAppearance = appearance
//                    viewController.navigationItem.standardAppearance = appearance
//                    viewController.navigationItem.setHidesBackButton(true, animated: false)
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
//                        nvc.setNavigationBarHidden(true, animated: false)
//                    }
                }
            }

            nvc.setSplitViewRoot(viewController: viewController, animated: animated)
            if immediatelyShow {
                show(column)
            }
        } else if self.viewController(for: column) == nil, let nvc = viewController as? UINavigationController {
            setViewController(nvc, for: column)
        }
    }
}

extension UINavigationController {
    func setSplitViewRoot(viewController: UIViewController, animated: Bool = true) {
        setSplitViewRoot(viewControllers: [viewController], animated: animated)
    }

    func setSplitViewRoot(viewControllers: [UIViewController], animated: Bool = true) {
        for viewController in viewControllers {
            if viewController.navigationItem.scrollEdgeAppearance == nil {
                viewController.navigationItem.scrollEdgeAppearance = UINavigationBarAppearance()
            }
        }
        setViewControllers(viewControllers, animated: animated)
    }
}

extension UIBarButtonItem {
    static func primaryToggleSidebarBarButtonItem(splitViewController: UISplitViewController?) -> UIBarButtonItem {
        return UIBarButtonItem(title: nil,
                               image: UIImage(systemName: "sidebar.left"),
                               primaryAction: .init(handler: { _ in
                                   if let splitViewController = splitViewController {
                                       if splitViewController.traitCollection.horizontalSizeClass == .compact {
                                           splitViewController.show(.supplementary)
                                       } else {
                                           splitViewController.hide(.primary)
                                       }
                                   }
                               }),
                               menu: nil)
    }

    static func supplementaryToggleSidebarBarButtonItem(splitViewController: UISplitViewController?) -> UIBarButtonItem {
        return UIBarButtonItem(title: nil,
                               image: UIImage(systemName: "sidebar.left"),
                               primaryAction: .init(handler: { _ in
                                   splitViewController?.show(.primary)
                               }),
                               menu: nil)
    }
}

extension UINavigationItem {
    func prependLeftBarButtonItems(_ item: UIBarButtonItem) {
        if let originalLeftBarButtonItems = leftBarButtonItems {
            leftBarButtonItems = [[item], originalLeftBarButtonItems].flatMap { $0 }
        } else {
            leftBarButtonItems = [item]
        }
    }
}
