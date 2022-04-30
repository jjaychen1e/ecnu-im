//
//  PostCommentCell.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/30.
//

import SnapKit
import UIKit

final class PostCommentCell: UICollectionViewCell {
    var post: FlarumPost? {
        didSet {
            setNeedsUpdateConfiguration()
        }
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        var newConfiguration = PostCommentCellConfiguration().updated(for: state)
        newConfiguration.post = post
        contentConfiguration = newConfiguration
    }
}

struct PostCommentCellConfiguration: UIContentConfiguration, Hashable {
    var post: FlarumPost?

    func makeContentView() -> UIView & UIContentView {
        PostCommentCellContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> PostCommentCellConfiguration {
        guard state is UICellConfigurationState else {
            return self
        }

        return self
    }
}

class PostCommentCellContentView: UIView, UIContentView {
    private lazy var authorLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    private lazy var idNumber: UILabel = {
        let label = UILabel()
        return label
    }()

    private var idNumberBottomConstraint: Constraint!

    private var postContentItemsUIView: PostContentItemsUIView?

    private var currentConfiguration: PostCommentCellConfiguration!
    var configuration: UIContentConfiguration {
        get { currentConfiguration }
        set {
            guard let newConfiguration = newValue as? PostCommentCellConfiguration else { return }
            apply(configuration: newConfiguration)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(configuration: PostCommentCellConfiguration) {
        super.init(frame: .zero)
        setViewHierarchy()
        apply(configuration: configuration)
    }

    private func setViewHierarchy() {
        addSubview(authorLabel)
        authorLabel.text = "@unknown"
        authorLabel.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
        }

        addSubview(idNumber)
        idNumber.text = "unknown id"
        idNumber.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(authorLabel.snp.bottom)
            idNumberBottomConstraint = make.bottom.equalToSuperview().constraint
        }
    }

    func apply(configuration: PostCommentCellConfiguration) {
        guard currentConfiguration != configuration else { return }
        currentConfiguration = configuration

        postContentItemsUIView?.removeFromSuperview()

        if let post = configuration.post, let content = post.attributes?.content, case let .comment(comment) = content {
            authorLabel.text = post.authorName
            if let id = post.attributes?.number {
                idNumber.text = "\(id)"
            } else {
                idNumber.text = "unknown parsed id"
            }

            let parseConfiguration = ParseConfiguration(imageOnTapAction: { ImageBrowser.shared.present(imageURLs: $1, selectedImageIndex: $0) },
                                                        imageGridDisplayMode: .narrow)
            let contentParser = ContentParser(content: comment, configuration: parseConfiguration)
            let newContentItems = contentParser.parse()
            if newContentItems.count > 0 {
                idNumberBottomConstraint.deactivate()
                let postContentItemsUIView = PostContentItemsUIView(contentItems: newContentItems)
                self.postContentItemsUIView = postContentItemsUIView
                addSubview(postContentItemsUIView)
                postContentItemsUIView.snp.makeConstraints { make in
                    make.leading.bottom.trailing.equalToSuperview()
                    make.top.equalTo(idNumber.snp.bottom)
                }
            } else {
                idNumberBottomConstraint.activate()
            }
        } else {
            authorLabel.text = "Update failed"
            idNumber.text = "Update failed"
            idNumberBottomConstraint.activate()
        }
    }
}
