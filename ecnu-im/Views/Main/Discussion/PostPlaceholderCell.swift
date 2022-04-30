//
//  PostPlaceholderCell.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/30.
//

import SwiftUI
import UIKit

private struct DiscussionViewPostCellPlaceholder: View {
    var body: some View {
        VStack {
            HStack {
                Circle()
                    .fill(Color(rgba: "#D6D6D6"))
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading) {
                    HStack {
                        Text("jjaychen")
                            .font(.system(size: 12, weight: .medium))
                        Text("1 分钟前")
                            .font(.system(size: 10, weight: .light))
                    }
                }
                Spacer()
            }
            Text(String(repeating: "那只敏捷的棕毛狐狸跳过那只懒狗，消失得无影无踪。", count: 10))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .redacted(reason: .placeholder)
    }
}

final class PostPlaceholderCell: UICollectionViewCell {
    override func updateConfiguration(using state: UICellConfigurationState) {
        contentConfiguration = PostPlaceholderCellConfiguration().updated(for: state)
    }
}

struct PostPlaceholderCellConfiguration: UIContentConfiguration, Hashable {
    func makeContentView() -> UIView & UIContentView {
        PostPlaceholderCellContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> PostPlaceholderCellConfiguration {
        guard state is UICellConfigurationState else {
            return self
        }

        return self
    }
}

class PostPlaceholderCellContentView: UIView, UIContentView {
    private var hostingVC: UIHostingController<DiscussionViewPostCellPlaceholder>!
    
    private var currentConfiguration: PostPlaceholderCellConfiguration!
    var configuration: UIContentConfiguration {
        get { currentConfiguration }
        set {
            guard let newConfiguration = newValue as? PostPlaceholderCellConfiguration else { return }
            apply(configuration: newConfiguration)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(configuration: PostPlaceholderCellConfiguration) {
        super.init(frame: .zero)
        setViewHierarchy()
        apply(configuration: configuration)
    }

    private func setViewHierarchy() {
        hostingVC = UIHostingController(rootView: DiscussionViewPostCellPlaceholder())
        addSubview(hostingVC.view)
        hostingVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func apply(configuration: PostPlaceholderCellConfiguration) {
        guard currentConfiguration != configuration else { return }
        currentConfiguration = configuration
    }
}
