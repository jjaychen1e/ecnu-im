//
//  DiscussionHeaderViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/30.
//

import SwiftUI
import UIKit

class DiscussionHeaderViewController: UIViewController {
    weak var splitVC: UISplitViewController?
    weak var nvc: UINavigationController?

    var discussion: FlarumDiscussion

    init(discussion: FlarumDiscussion) {
        self.discussion = discussion
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let headerBackgroundView = UIView()
        if let cgColor = (discussion.synthesizedTags.first?.backgroundColor ?? .gray).cgColor {
            headerBackgroundView.backgroundColor = UIColor(cgColor: cgColor)
        } else {
            headerBackgroundView.backgroundColor = .gray
        }
        view.addSubview(headerBackgroundView)
        headerBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let headerHostingVC = UIHostingController(rootView:
            DiscussionHeaderView(discussion: discussion)
                .environment(\.splitVC, splitViewController ?? splitVC)
                .environment(\.nvc, navigationController ?? nvc))
        headerHostingVC.view.backgroundColor = .clear
        addChildViewController(headerHostingVC)
        headerHostingVC.view.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
    }
}
