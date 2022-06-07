//
//  NoNavigationBarNavigationController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/22.
//

import UIKit

class NoNavigationBarNavigationController: UINavigationController {
    private var _isNavigationBarHidden = true

    override var isNavigationBarHidden: Bool {
        get {
            _isNavigationBarHidden
        }
        set {}
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        self.navigationBar.standardAppearance = appearance
        self.navigationBar.scrollEdgeAppearance = appearance
        self.navigationBar.compactAppearance = appearance
        self.navigationBar.compactScrollEdgeAppearance = appearance
        setNavigationBarHidden(true, animated: false)
    }

    override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        _isNavigationBarHidden = true
        super.setNavigationBarHidden(true, animated: animated)
    }

    func _setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        _isNavigationBarHidden = hidden
        super.setNavigationBarHidden(hidden, animated: animated)
    }
}
