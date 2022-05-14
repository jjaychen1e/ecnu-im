//
//  NoNavigationBarViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/22.
//

import UIKit

class NoNavigationBarViewController: UIViewController {
    private weak var navigationBarTimer: Timer?
    override func viewDidLoad() {
        super.viewDidLoad()
        // UISplitViewController will show UINavigationBar in many cases. It will be displayed
        // even we hide it in `viewDidLoad`. And when present another VC, it will be displayed, too.
        navigationBarTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            if let self = self {
                self.navigationController?.isNavigationBarHidden = true
            }
        }
    }

    deinit {
        navigationBarTimer?.invalidate()
        if let _ = navigationController?.viewControllers.last as? NoNavigationBarViewController {
            return
        }
        navigationController?.isNavigationBarHidden = false
    }
}
