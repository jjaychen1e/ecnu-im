//
//  HasNavigationPermission.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/19.
//

import Foundation
import UIKit

enum NavigationPermission {
    case login
}

protocol HasNavigationPermission: UIViewController {
    func navigationPermission() -> NavigationPermission
}

extension HasNavigationPermission {
    func navigationPermission() -> NavigationPermission {
        .login
    }
}
