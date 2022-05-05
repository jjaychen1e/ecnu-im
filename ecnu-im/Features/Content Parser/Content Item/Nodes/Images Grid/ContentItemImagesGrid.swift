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

    var imageView: UIImageView!

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        imageView.kf.cancelDownloadTask()
    }

    init(urls: [URL], index: Int, onTapAction: @escaping (Int, [URL]) -> Void) {
        self.urls = urls
        self.index = index
        self.onTapAction = onTapAction
        super.init(frame: .zero)

        let imageView = UIImageView(frame: .zero)
        self.imageView = imageView
        imageView.contentMode = .scaleAspectFill
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(with: urls[index], placeholder: urls[index].hashedColor.image(), options: [.transition(.fade(0.2))]) { [weak self] result in
            if case let .success(value) = result {
                ImageSizeStorage.shared.store(size: value.image.size, url: urls[index])
            }
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        onTapAction(index, urls)
    }
}

class ContentItemImagesGridUIView: UIView & ContentBlockUIView {
    var urls: [URL]
    var configuration: ParseConfiguration

    private var imageViews: [ContentItemGridImageUIView] = []

    private let margin: CGFloat = 4.0
    private let columnCount = 3
    private var lineCount: CGFloat {
        ceil(CGFloat(urls.count) / CGFloat(columnCount))
    }

    private func imageWidth(frameWidth: CGFloat) -> CGFloat {
        (frameWidth - CGFloat(columnCount - 1) * margin) / CGFloat(columnCount)
    }

    private func imageSize(frameWidth: CGFloat) -> CGSize {
        let imageWidth = imageWidth(frameWidth: frameWidth)
        return CGSize(width: imageWidth, height: imageWidth)
    }

    private var currentSize: CGSize = .zero

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard size.width > 0 else { return .zero }
        return CGSize(width: size.width, height: lineCount * (imageWidth(frameWidth: size.width) + margin) - margin)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        for i in 0 ..< urls.count {
            let lineOffset = i / columnCount
            let inlineOffset = i % columnCount
            let imageWidth = imageWidth(frameWidth: bounds.width)
            imageViews[i].frame = .init(origin: .init(x: (imageWidth + margin) * CGFloat(inlineOffset),
                                                      y: (imageWidth + margin) * CGFloat(lineOffset)),
                                        size: imageSize(frameWidth: bounds.width))
        }
        currentSize = sizeThatFits(bounds.size)
        invalidateIntrinsicContentSize()
    }

    init(urls: [URL], configuration: ParseConfiguration, updateLayout: (() -> Void)?) {
        self.urls = urls
        self.configuration = configuration
        super.init(frame: .zero)

        imageViews = (0 ..< urls.count).map {
            let imageView = ContentItemGridImageUIView(urls: urls, index: $0, onTapAction: configuration.imageOnTapAction)
            addSubview(imageView)
            imageView.clipsToBounds = true
            return imageView
        }
    }

    override var intrinsicContentSize: CGSize {
        let size = currentSize
        return size
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
