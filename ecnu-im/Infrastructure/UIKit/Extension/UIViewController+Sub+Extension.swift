//
//  UIViewController+Sub+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/3.
//

import Foundation
import UIKit
import SnapKit

extension UIViewController {
    func addSubViewController(_ viewController: UIViewController, addConstrains: Bool = false) {
        view.addSubview(viewController.view)
        viewController.willMove(toParent: self)
        addChild(viewController)
        viewController.didMove(toParent: self)
        if addConstrains {
            viewController.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
