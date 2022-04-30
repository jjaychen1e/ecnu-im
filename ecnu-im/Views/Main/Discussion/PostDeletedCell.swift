//
//  PostDeletedCell.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/30.
//

import UIKit

final class PostDeletedCell: UICollectionViewCell {
    override func updateConfiguration(using state: UICellConfigurationState) {
        contentConfiguration = PostDeletedCellConfiguration().updated(for: state)
    }
}

struct PostDeletedCellConfiguration: UIContentConfiguration, Hashable {
    func makeContentView() -> UIView & UIContentView {
        PostDeletedCellContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> PostDeletedCellConfiguration {
        guard state is UICellConfigurationState else {
            return self
        }

        return self
    }
}

class PostDeletedCellContentView: UIView, UIContentView {
    
    private var currentConfiguration: PostDeletedCellConfiguration!
    var configuration: UIContentConfiguration {
        get { currentConfiguration }
        set {
            guard let newConfiguration = newValue as? PostDeletedCellConfiguration else { return }
            apply(configuration: newConfiguration)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(configuration: PostDeletedCellConfiguration) {
        super.init(frame: .zero)
        setViewHierarchy()
        apply(configuration: configuration)
    }

    private func setViewHierarchy() {
        let deletedView = UIView()
        addSubview(deletedView)
        deletedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(0).priority(.required)
        }
    }

    func apply(configuration: PostDeletedCellConfiguration) {
        guard currentConfiguration != configuration else { return }
        currentConfiguration = configuration
    }
}
