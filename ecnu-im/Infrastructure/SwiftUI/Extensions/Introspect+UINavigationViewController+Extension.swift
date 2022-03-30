//
//  Introspect+UINavigationViewController+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/2.
//

import Foundation
import UIKit
import SwiftUI

private struct UINavigationViewControllerKey: EnvironmentKey {
    static let defaultValue: UINavigationController? = nil
}

extension EnvironmentValues {
    var nvc: UINavigationController? {
        get { self[UINavigationViewControllerKey.self] }
        set { self[UINavigationViewControllerKey.self] = newValue }
    }
}
