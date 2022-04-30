//
//  ContentItemSingleImage.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/28.
//

import Kingfisher
import SwiftUI
import UIKit

struct ContentItemSingleImage: View {
    @State var url: URL
    @State var onTapAction: (Int, [URL]) -> Void

    var body: some View {
        KFImage.url(url)
            .placeholder {
                ProgressView()
            }
            .loadDiskFileSynchronously()
            .cancelOnDisappear(true)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: 300)
            .onTapGesture {
                onTapAction(0, [url])
            }
            .contextMenu {
                Button(action: {}) {
                    Text("This is a test")
                    Image(systemName: "paintbrush")
                }
            }
    }
}

class ContentItemSingleImageUIView: UIView {
    var url: URL
    var onTapAction: (Int, [URL]) -> Void

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(url: URL, onTapAction: @escaping (Int, [URL]) -> Void) {
        self.url = url
        self.onTapAction = onTapAction
        super.init(frame: .zero)

        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.height.lessThanOrEqualTo(300)
            make.edges.equalToSuperview()
        }
        imageView.kf.indicatorType = .activity
        // , placeholder: UIProgressView()
        imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))]) { result in
            switch result {
            case let .success(value):
//                print(value)
                break
            case let .failure(error):
//                print(error) // The error happens
                break
            }
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        onTapAction(0, [url])
    }
}

extension UIProgressView: Placeholder {}
