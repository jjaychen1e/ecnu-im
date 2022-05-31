//
//  CommonWebViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/21.
//

import UIKit
import WebController

class CommonWebViewController: UIViewController, WebControllerDelegate {
    private var startURL: URL
    private var jsAction: String?

    init(url: URL, jsActionOnLoad: String? = nil) {
        startURL = url
        jsAction = jsActionOnLoad
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var webController: WebController!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
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
        webController.indicatorView.alpha = 0.0
        webController.webView.isOpaque = false
        webController.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(done)),
            UIBarButtonItem(image: UIImage(systemName: "safari"), style: .plain, target: self, action: #selector(openInSafari)),
        ]
        webController.load(startURL)
        let nvc = UINavigationController(rootViewController: webController)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        nvc.navigationBar.standardAppearance = appearance
        nvc.navigationBar.scrollEdgeAppearance = appearance
        nvc.navigationBar.compactAppearance = appearance
        nvc.navigationBar.compactScrollEdgeAppearance = appearance
        addChildViewController(nvc, addConstrains: true)
    }

    @objc
    func openInSafari() {
        if let url = webController.webView.url,
           let urlWithPercentEncoding = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let url = URLService.safari(href: urlWithPercentEncoding).url.url {
                UIApplication.shared.open(url)
            }
        }
    }

    @objc
    func done() {
        dismiss(animated: true)
    }

    static func show(url: URL, jsActionOnLoad: String? = nil) {
        let commonWebViewController = CommonWebViewController(url: url, jsActionOnLoad: jsActionOnLoad)
        commonWebViewController.modalPresentationStyle = .fullScreen
        UIApplication.shared.presentOnTop(commonWebViewController, animated: true)
    }

    func webController(_ webController: WebController, title: String?) -> String? {
        return title?.appending(" ❤️")
    }

    func webController(_ webController: WebController, didFinish url: URL) {
        if url.absoluteURL == startURL.absoluteURL, let jsAction = jsAction {
            webController.evaluateJavaScript(jsAction, completionHandler: { _, _ in })
        }
    }
}
