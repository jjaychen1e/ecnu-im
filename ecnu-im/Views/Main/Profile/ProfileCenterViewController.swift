//
//  ProfileCenterViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/14.
//

import Combine
import SwiftUI
import UIKit

private struct ProfileCenterViewWrapper: View {
    private var view: ProfileCenterView
    private var splitVC: UISplitViewController?
    private var nvc: UINavigationController?
    private var vc: UIViewController?

    private let environmentView: EnvironmentWrapperView<ProfileCenterView>

    init(_ view: ProfileCenterView, splitVC: UISplitViewController?, nvc: UINavigationController?, vc: UIViewController?) {
        self.view = view
        self.splitVC = splitVC
        self.nvc = nvc
        self.vc = vc
        environmentView = EnvironmentWrapperView(view, splitVC: splitVC, nvc: nvc, vc: vc)
    }

    var body: some View {
        environmentView
    }

    func update(userId: String) {
        view.update(userId: userId)
    }

    func update(selectedCategory: ProfileCategory) {
        view.update(selectedCategory: selectedCategory)
    }
}

class ProfileCenterViewController: NoNavigationBarViewController, NoOverlayViewController, HasNavigationPermission {
    weak var splitVC: UISplitViewController?
    weak var nvc: UINavigationController?

    fileprivate var userId: String
    fileprivate var hostingVC: UIHostingController<ProfileCenterViewWrapper>!

    private var initSelectedCategory: ProfileCategory?

    init(userId: String) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func shouldPushTo(nvc: UINavigationController?) -> Bool {
        if let top = nvc?.topViewController,
           let another = top as? ProfileCenterViewController {
            return userId != another.userId
        }
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let vc = UIHostingController(rootView: ProfileCenterViewWrapper(ProfileCenterView(userId: userId),
                                                                        splitVC: splitViewController ?? splitVC,
                                                                        nvc: navigationController ?? nvc,
                                                                        vc: self)
        )
        hostingVC = vc
        addChildViewController(vc, addConstrains: true)
        if let initSelectedCategory = initSelectedCategory {
            hostingVC.rootView.update(selectedCategory: initSelectedCategory)
            self.initSelectedCategory = nil
        }
    }

    func update(userId: String) {
        self.userId = userId
        hostingVC.rootView.update(userId: userId)
    }

    func selectTab(selectedCategory: ProfileCategory) {
        if let hostingVC = hostingVC {
            hostingVC.rootView.update(selectedCategory: selectedCategory)
        } else {
            initSelectedCategory = selectedCategory
        }
    }
}

class MyProfileCenterViewController: ProfileCenterViewController, CanSelectWithInfo {
    private var subscriptions: Set<AnyCancellable> = []

    init() {
        super.init(userId: AppGlobalState.shared.account?.userIdString ?? "")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        AppGlobalState.shared.$tokenPrepared.sink { [weak self] change in
            if let self = self {
                if self.userId != AppGlobalState.shared.account?.userIdString {
                    self.update(userId: AppGlobalState.shared.account?.userIdString ?? "")
                }
            }
        }.store(in: &subscriptions)
    }

    func config(info: [String: Any]) {
        if let profileCategory = info[ProfileCategory.key] as? ProfileCategory {
            selectTab(selectedCategory: profileCategory)
        }
    }
}
