//
//  AllDiscussionTagFilterViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/6/4.
//

import SwiftUI
import UIKit

class AllDiscussionTagFilterViewController: UIViewController, HasNavigationPermission {
    private var hostingViewController: UIHostingController<EnvironmentWrapperView<AllDiscussionTagFilterView>>!

    private var viewModel: AllDiscussionTagFilterViewModel

    init(viewModel: AllDiscussionTagFilterViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let environmentWrapperView = EnvironmentWrapperView(
            AllDiscussionTagFilterView(viewModel: viewModel),
            splitVC: splitViewController,
            nvc: navigationController,
            vc: self
        )

        let hostingViewController = UIHostingController(rootView: environmentWrapperView)
        self.hostingViewController = hostingViewController
        let navigationWrapperViewController = NavigationWrapperViewController(viewController: hostingViewController, isPresented: isBeingPresented)
        environmentWrapperView.update(navWrapperVC: navigationWrapperViewController)
        addChildViewController(navigationWrapperViewController, addConstrains: true)
    }
}
