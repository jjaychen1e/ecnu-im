//
//  NavigationViwe+BackGesture+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/1.
//

import Foundation
import RxCocoa
import RxSwift
import UIKit

// https://stackoverflow.com/a/60067869
// Back gesture will be disabled when using `.navigationBarHidden(true)`
// This allows hiding navigation title without losing gesture
extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

// public extension UINavigationController {
//    @objc func customViewDidLoad() {
//        super.viewDidLoad()
//        interactivePopGestureRecognizer?.delegate = self
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//            self.setNavigationBarHidden(true, animated: false)
//        }
//    }
//
//    private static let swizzleDesriptionImplementation: Void = {
//        let originalMethod = class_getInstanceMethod(UINavigationController.self, #selector(viewDidLoad))
//        let swizzledMethod = class_getInstanceMethod(UINavigationController.self, #selector(customViewDidLoad))
//        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
//            // switch implementation..
//            method_exchangeImplementations(originalMethod, swizzledMethod)
//        }
//    }()
//
//    static func swizzleDesription() {
//        _ = swizzleDesriptionImplementation
//    }
// }
