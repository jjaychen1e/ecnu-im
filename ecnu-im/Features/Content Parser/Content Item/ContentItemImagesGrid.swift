//
//  ContentItemImagesGrid.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/28.
//

import Kingfisher
import SwiftUI

private struct ParsedGridImageView: View {
    @State var urls: [URL]
    @State var index: Int
    @State var onTapAction: (Int, [URL]) -> Void

    var body: some View {
        KFImage.url(urls[index])
            .placeholder {
                ProgressView()
            }
            .loadDiskFileSynchronously()
            .cancelOnDisappear(true)
            .resizable()
            .scaledToFill()
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .clipped()
            .contentShape(Rectangle()) // Clipped cause tappable area overflow
            .onTapGesture {
                onTapAction(index, urls)
            }
            .contextMenu {
                Button(action: {}) {
                    Text("This is a test")
                    Image(systemName: "paintbrush")
                }
            }
    }
}

struct ContentItemImagesGrid: View {
    @State var urls: [URL]
    @State var configuration: ParseConfiguration

    var body: some View {
        let gridLayout: [GridItem] = Array(repeating: .init(.flexible()), count: 3)

        // https://stackoverflow.com/a/64252041
        LazyVGrid(columns: gridLayout, alignment: .center, spacing: 10) {
            ForEach(0 ..< urls.count, id: \.self) { i in
                ParsedGridImageView(urls: urls, index: i, onTapAction: configuration.imageOnTapAction)
            }
        }
    }
}

private class ContentItemGridImageUIView: UIView {
    var urls: [URL]
    var index: Int
    var onTapAction: (Int, [URL]) -> Void

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(urls: [URL], index: Int, onTapAction: @escaping (Int, [URL]) -> Void) {
        self.urls = urls
        self.index = index
        self.onTapAction = onTapAction
        super.init(frame: .zero)

        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(with: urls[index], options: [.transition(.fade(0.2))]) { _ in
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        onTapAction(index, urls)
    }
}

class ContentItemImagesGridUIView: UIView {
    var urls: [URL]
    var configuration: ParseConfiguration

    private lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 4
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        return stackView
    }()

    private func horizontalStackView(imageIndices: [Int]) -> UIStackView {
        let stackView = UIStackView()
        stackView.spacing = 4
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually

        for imageIndex in imageIndices {
            let imageView = ContentItemGridImageUIView(urls: urls, index: imageIndex, onTapAction: configuration.imageOnTapAction)
            imageView.clipsToBounds = true
            imageView.snp.makeConstraints { make in
                make.width.equalTo(imageView.snp.height)
            }
            stackView.addArrangedSubview(imageView)
        }

        return stackView
    }

    init(urls: [URL], configuration: ParseConfiguration) {
        self.urls = urls
        self.configuration = configuration
        super.init(frame: .zero)
        addSubview(verticalStackView)
        verticalStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let size = 3
        stride(from: 0, to: urls.count, by: size).map {
            Array($0 ..< min(urls.count, $0 + size))
        }.map {
            horizontalStackView(imageIndices: $0)
        }.forEach { horizontalStackView in
            verticalStackView.addArrangedSubview(horizontalStackView)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
