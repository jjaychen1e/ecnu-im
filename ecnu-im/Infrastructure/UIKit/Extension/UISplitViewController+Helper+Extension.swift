//
//  UISplitViewController+Helper+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/3.
//

import Foundation
import SwiftUI
import UIKit

extension UISplitViewController {
    var primaryNVC: UINavigationController? {
        if let primaryNVC = viewController(for: .primary) as? UINavigationController {
            return primaryNVC
        }
        return nil
    }

    var secondaryNVC: UINavigationController? {
        if let secondaryNVC = viewController(for: .secondary) as? UINavigationController {
            return secondaryNVC
        }
        return nil
    }

    func push(viewController: UIViewController, column: UISplitViewController.Column, animated: Bool = true, toRoot: Bool = false, ext: [String: Any] = [:]) {
        if let nvc = self.viewController(for: column) as? UINavigationController {
            if let noOverlayVC = viewController as? NoOverlayViewController {
                if !noOverlayVC.shouldPushTo(nvc: nvc), !noOverlayVC.shouldReactTo(nvc: nvc, ext: ext) {
                    show(column) // insurance
                    return
                }
            }

            if let hasNavigationPermission = viewController as? HasNavigationPermission {
                switch hasNavigationPermission.navigationPermission() {
                case .login:
                    if !AppGlobalState.shared.tokenPrepared {
                        UIApplication.shared.topController()?.presentSignView()
                        return
                    }
                }
            }

            if viewController.navigationItem.scrollEdgeAppearance == nil {
                viewController.navigationItem.scrollEdgeAppearance = UINavigationBarAppearance()
            }

            if isCollapsed {
                if secondaryNVC == nvc,
                   nvc.viewControllers.count == 0,
                   primaryNVC?.topViewController !== nvc {
                    // nvc.viewControllers.count == 0 only when in compact mode, secondary column
                    nvc.viewControllers = [viewController]
                    primaryNVC?.pushViewController(nvc, animated: true)
                    return
                }
            }

            if toRoot, nvc === secondaryNVC {
                if isCollapsed {
                    nvc.viewControllers = [viewController]
                    return
                } else if let first = nvc.viewControllers.first {
                    nvc.viewControllers = [first, viewController]
                    return
                }
            }

            var animated = animated
            if nvc === secondaryNVC,
               !isCollapsed,
               nvc.viewControllers.count == 1 {
                animated = false
            }

            if animated {
                nvc.pushViewController(viewController, animated: animated)
            } else {
                nvc.viewControllers = nvc.viewControllers + [viewController]
            }
        }
    }

    func pop(from nvc: UINavigationController?, animated: Bool = true) {
        if let nvc = nvc {
            if nvc === primaryNVC {
                nvc.popViewController(animated: animated)
            } else if nvc === secondaryNVC {
                if isCollapsed,
                   nvc.viewControllers.count == 1,
                   let primaryNVC = primaryNVC {
                    // only when in compact mode, since there is no empty view placeholder
                    primaryNVC.popViewController(animated: animated)
                    return
                }

                nvc.popViewController(animated: animated)
            }
        }
    }
}
