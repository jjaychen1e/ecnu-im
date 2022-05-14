//
//  UIView+ParentController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/14.
//

import UIKit

/// https://stackoverflow.com/a/24590678
extension UIView {
    var parentViewController: UIViewController? {
        // Starts from next (As we know self is not a UIViewController).
        var parentResponder: UIResponder? = next
        while parentResponder != nil {
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
            parentResponder = parentResponder?.next
        }
        return nil
    }
}
