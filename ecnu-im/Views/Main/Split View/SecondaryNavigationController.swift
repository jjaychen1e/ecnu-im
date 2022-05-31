//
//  SecondaryNavigationController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/31.
//

import UIKit

class SecondaryNavigationController: NoNavigationBarNavigationController {
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent {
            viewControllers = []
        }
    }
}
