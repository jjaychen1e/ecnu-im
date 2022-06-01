//
//  NoNavigationBarNavigationController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/22.
//

import UIKit

class NoNavigationBarNavigationController: UINavigationController {
    private var _isNavigationBarHidden = false

    override var isNavigationBarHidden: Bool {
        get {
            _isNavigationBarHidden
        }
        set {}
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        super.setNavigationBarHidden(true, animated: animated)
    }

    func _setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        _isNavigationBarHidden = hidden
        super.setNavigationBarHidden(hidden, animated: animated)
    }
}
