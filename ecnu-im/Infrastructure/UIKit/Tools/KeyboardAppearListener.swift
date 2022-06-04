//
//  KeyboardAppearListener.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/15.
//

import Foundation
import UIKit

/// https://gist.github.com/matkuznik/209fd435b97dc8713cf0d5afbe7419b3
/// https://medium.com/azimolabs/how-to-handle-keyboard-behavior-in-ios-apps-3098a8c5411a
class KeyboardAppearListener {
    private var showKeyboard: NSObjectProtocol?
    private var hideKeyboard: NSObjectProtocol?

    private weak var viewController: UIViewController?
    private var callback: (_ fromOffsetHeight: CGFloat, _ toOffsetHeight: CGFloat, _ duration: CGFloat, _ curve: UIView.AnimationCurve) -> Void

    private var previousHeightOffset: CGFloat = 0.0

    let defaultAdditionalSafeAreaInsetCallback: (_ fromOffsetHeight: CGFloat, _ toOffsetHeight: CGFloat, _ duration: CGFloat, _ curve: UIView.AnimationCurve) -> Void = { fromOffsetHeight, toOffsetHeight, duration, curve in
    }

    init(
        viewController: UIViewController,
        callback: @escaping (_ fromOffsetHeight: CGFloat, _ toOffsetHeight: CGFloat, _ duration: CGFloat, _ curve: UIView.AnimationCurve) -> Void
    ) {
        self.viewController = viewController
        self.callback = callback
        showKeyboard = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notification in
            self?.keyboardWillShow(notification: notification)
        }

        hideKeyboard = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] notification in
            self?.keyboardWillHide(notification: notification)
        }
    }

    private func keyboardWillShow(notification: Notification) {
        printDebug("")
        guard
            let viewController = viewController,
            let userInfo = notification.userInfo,
            let beginKeyboardFrame = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect,
            let endKeyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            beginKeyboardFrame != .zero
        else {
            return
        }
        let fromOffsetHeight = previousHeightOffset
        previousHeightOffset = 0

        if let superview = viewController.view.superview,
           let window = viewController.view.window {
            let rect = superview.convert(viewController.view.frame, to: window.screen.coordinateSpace)
            previousHeightOffset -= (window.screen.bounds.height - rect.maxY)
            previousHeightOffset += window.screen.bounds.height - endKeyboardFrame.origin.y
        }

        notifyChange(fromOffsetHeight: fromOffsetHeight, toOffsetHeight: previousHeightOffset, userInfo)
    }

    private func keyboardWillHide(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }

        let fromOffsetHeight = previousHeightOffset
        previousHeightOffset = 0

        notifyChange(fromOffsetHeight: fromOffsetHeight, toOffsetHeight: 0, userInfo)
    }

    private func notifyChange(fromOffsetHeight: CGFloat, toOffsetHeight: CGFloat, _ userInfo: [AnyHashable: Any]) {
        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey]
            .flatMap { $0 as? Double } ?? 0.25

        let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey]
            .flatMap { $0 as? Int }
            .flatMap { UIView.AnimationCurve(rawValue: $0) } ?? .easeInOut

        callback(fromOffsetHeight, toOffsetHeight, duration, curve)
    }
}
