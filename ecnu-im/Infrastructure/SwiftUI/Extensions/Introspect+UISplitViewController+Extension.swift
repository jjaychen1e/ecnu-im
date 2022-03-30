//
//  Introspect+UISplitViewController+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/2.
//

import Foundation
import UIKit
import SwiftUI

private struct UISplitViewControllerKey: EnvironmentKey {
    static let defaultValue: UISplitViewController? = nil
}

extension EnvironmentValues {
    var splitVC: UISplitViewController? {
        get { self[UISplitViewControllerKey.self] }
        set { self[UISplitViewControllerKey.self] = newValue }
    }
}
