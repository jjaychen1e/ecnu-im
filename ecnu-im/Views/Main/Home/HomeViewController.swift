//
//  HomeViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/22.
//

import SwiftUI
import UIKit
import SafariServices

class HomeViewController: NoNavigationBarViewController {
    weak var splitVC: UISplitViewController?
    weak var nvc: UINavigationController?

    private var hostingVC: UIHostingController<EnvironmentWrapperView<HomeView>>!

    override func viewDidLoad() {
        super.viewDidLoad()

        let vc = UIHostingController(rootView: EnvironmentWrapperView(
            HomeView(),
            splitVC: splitViewController ?? splitVC,
            nvc: navigationController ?? nvc,
            vc: self
        ), disableKeyboardNotification: true)
        hostingVC = vc
        addChildViewController(vc, addConstrains: false)
        vc.view.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let alertController = UIAlertController(title: "注意", message: "恭喜您注册成功，请登录校园邮箱以激活账号。您想要现在打开腾讯企业邮箱吗？", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "确定", style: .destructive, handler: { action in
                EmailVerificationViewController.show()
            }))
            alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { action in
            }))
            UIApplication.shared.topController()?.present(alertController, animated: true)
        }
    }
}
