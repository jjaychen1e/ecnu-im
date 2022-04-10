//
//  UIViewController+Sub+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/3.
//

import Foundation
import SnapKit
import UIKit

extension UIViewController {
    private func _convenientlyAddChildViewController(_ viewController: UIViewController, addConstrains: Bool = false) {
        viewController.willMove(toParent: self)
        addChild(viewController)
        viewController.didMove(toParent: self)
        if addConstrains {
            viewController.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    func addChildViewController(_ viewController: UIViewController, addConstrains: Bool = false) {
        view.addSubview(viewController.view)
        _convenientlyAddChildViewController(viewController, addConstrains: addConstrains)
    }

    func insertChildViewController(_ viewController: UIViewController, at index: Int, addConstrains: Bool = false) {
        view.insertSubview(viewController.view, at: index)
        _convenientlyAddChildViewController(viewController, addConstrains: addConstrains)
    }

    func safelyRemoveFromParent() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
        didMove(toParent: nil)
    }
}
