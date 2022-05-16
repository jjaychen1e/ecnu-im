//
//  DiscussionHeaderViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/30.
//

import SwiftUI
import SwiftyJSON
import UIKit

class DiscussionHeaderViewController: UIViewController {
    weak var splitVC: UISplitViewController?
    weak var nvc: UINavigationController?

    private var viewModel: DiscussionHeaderViewModel

    private var headerBackgroundView = UIView()
    private var headerHostingVC: UIHostingController<EnvironmentWrapperView<DiscussionHeaderView>>!

    init(discussion: FlarumDiscussion) {
        viewModel = .init(discussion: discussion)
        super.init(nibName: nil, bundle: nil)

        if discussion.relationships?.tags == nil {
            Task {
                if let id = Int(discussion.id),
                   let response = try? await flarumProvider.request(.discussionInfo(discussionID: id)).flarumResponse() {
                    if let first = response.data.discussions.first {
                        viewModel.discussion = first
                        self.headerHostingVC.safelyRemoveFromParent()
                        self.setUpViews(viewModel: viewModel)
                    }
                }
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews(viewModel: viewModel)
    }

    private func setUpViews(viewModel: DiscussionHeaderViewModel) {
        if let cgColor = (viewModel.discussion.synthesizedTags.first?.backgroundColor ?? .gray).cgColor {
            headerBackgroundView.backgroundColor = UIColor(cgColor: cgColor)
        } else {
            headerBackgroundView.backgroundColor = .gray
        }
        view.addSubview(headerBackgroundView)
        headerBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let headerHostingVC = UIHostingController(rootView: EnvironmentWrapperView(
            DiscussionHeaderView(viewModel: viewModel),
            splitVC: splitViewController ?? splitVC,
            nvc: navigationController ?? nvc,
            vc: self
        ), ignoreSafeArea: true)
        self.headerHostingVC = headerHostingVC
        headerHostingVC.view.backgroundColor = .clear
        addChildViewController(headerHostingVC)
        headerHostingVC.view.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
    }
}
