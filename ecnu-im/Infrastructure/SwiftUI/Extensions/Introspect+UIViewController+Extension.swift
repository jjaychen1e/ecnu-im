//
//  Introspect+UIViewController+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/12.
//

import Foundation
import UIKit
import SwiftUI

private struct UIViewControllerKey: EnvironmentKey {
    static let defaultValue: UIViewController? = nil
}

extension EnvironmentValues {
    var viewController: UIViewController? {
        get { self[UIViewControllerKey.self] }
        set { self[UIViewControllerKey.self] = newValue }
    }
}
