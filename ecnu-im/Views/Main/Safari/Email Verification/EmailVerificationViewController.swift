//
//  EmailVerificationViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/20.
//

import UIKit
import WebController

class EmailVerificationViewController: UIViewController, WebControllerDelegate {
    let url = URL(string: "https://exmail.qq.com/login")!

    private var webController: WebController!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let webController = WebController()
        self.webController = webController
        webController.delegate = self
        webController.defaultCookies = [AppGlobalState.shared.flarumCookie].compactMap { $0 }
        webController.toolView.setBackBarButtonItem(UIImage(named: "icBack"))
        webController.toolView.setForwardBarButtonItem(UIImage(named: "icFront"))
        webController.toolView.tintColor = .white
        webController.toolView.barTintColor = UIColor.black
        webController.toolView.toolbar.isTranslucent = false
        webController.barTintColor = .black
        webController.titleTintColor = .white
        webController.progressView.trackTintColor = .white
        webController.progressView.progressTintColor = .black
        webController.indicatorView.color = .white
        webController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(done))
        webController.load(url)
        let nvc = UINavigationController(rootViewController: webController)
        addChildViewController(nvc, addConstrains: true)
    }

    @objc
    func done() {
        dismiss(animated: true)
    }

    static func show() {
        let emailVerificationViewController = EmailVerificationViewController()
        emailVerificationViewController.modalPresentationStyle = .fullScreen
        UIApplication.shared.presentOnTop(emailVerificationViewController, animated: true)
    }

    func webController(_ webController: WebController, error: Error) {
        printDebug("error: \(error)")
    }

    func webController(_ webController: WebController, didLoading: Bool) {
        printDebug("didLoading: \(didLoading)")
    }

    func webController(_ webController: WebController, didChangeURL: URL?) {
        guard let didChangeURL = didChangeURL else { return }
        printDebug("didChangeURL: \(didChangeURL)")
    }

    func webController(_ webController: WebController, didChangeTitle: String?) {
        guard let didChangeTitle = didChangeTitle else { return }
        printDebug("didChangeTitle: \(didChangeTitle)")
    }

    func webController(_ webController: WebController, title: String?) -> String? {
        return title?.appending(" ❤️")
    }

    func webController(_ webController: WebController, didFinish: URL) {
        if url.absoluteString.starts(with: "https://ecnu.im/confirm") {
            if AppGlobalState.shared.userInfo?.isEmailConfirmed != true {
                AppGlobalState.shared.emailVerificationEvent.send()
            }
        }
    }
}
