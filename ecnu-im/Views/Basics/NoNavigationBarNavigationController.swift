//
//  NoNavigationBarNavigationController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/22.
//

import UIKit

class NoNavigationBarNavigationController: UINavigationController {
    override var isNavigationBarHidden: Bool {
        get {
            true
        }
        set {}
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isNavigationBarHidden = true
    }

    override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        super.setNavigationBarHidden(true, animated: animated)
    }
}
