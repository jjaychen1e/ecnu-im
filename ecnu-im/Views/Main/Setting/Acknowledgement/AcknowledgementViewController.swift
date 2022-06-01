//
//  AcknowledgementViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/6/1.
//

import SwiftUI
import UIKit

class AcknowledgementViewController: UIViewController {
    private var hostingViewController: UIHostingController<EnvironmentWrapperView<AcknowledgementView>>!
    weak var splitVC: UISplitViewController?
    weak var nvc: UINavigationController?

    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingViewController = UIHostingController(rootView: EnvironmentWrapperView(
            AcknowledgementView(),
            splitVC: splitViewController ?? splitVC,
            nvc: navigationController ?? nvc,
            vc: self
        ))
        self.hostingViewController = hostingViewController
        let navigationWrappedViewController = NavigationWrappedViewController(viewController: hostingViewController, isPresented: isBeingPresented)
        addChildViewController(navigationWrappedViewController, addConstrains: true)
    }
}
