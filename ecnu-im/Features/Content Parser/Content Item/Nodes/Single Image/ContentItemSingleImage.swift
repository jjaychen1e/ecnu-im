//
//  ContentItemSingleImage.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/28.
//

import Cache
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

class ContentItemSingleImageUIView: UIView & ContentBlockUIView {
    var url: URL
    var onTapAction: (Int, [URL]) -> Void

    private var imageView: UIImageView!

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        imageView.kf.cancelDownloadTask()
    }

    init(url: URL, onTapAction: @escaping (Int, [URL]) -> Void, updateLayout: (() -> Void)?) {
        self.url = url
        self.onTapAction = onTapAction
        super.init(frame: .zero)

        imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        imageView.kf.indicatorType = .activity
        imageSize()
        imageView.kf.setImage(with: url, placeholder: url.hashedColor.image(), options: [.transition(.fade(0.2))]) { [weak self] result in
            if let self = self {
                if self._imageSize == nil {
                    if case let .success(value) = result {
                        ImageSizeStorage.shared.store(size: value.image.size, url: url)
                    }
                    updateLayout?()
                }
            }
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        onTapAction(0, [url])
    }

    private var _imageSize: CGSize?

    @discardableResult
    private func imageSize() -> CGSize? {
        if _imageSize != nil {
            return _imageSize
        }

        if let size = imageView.image?.size {
            _imageSize = size
            return size
        } else {
            if let size = ImageSizeStorage.shared.size(for: url) {
                _imageSize = size
                return size
            }
        }
        return nil
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard size.width > 0 else { return .zero }
        if let imageSize = imageSize() {
            let aspectRatio = imageSize.width / imageSize.height
            if size.width / aspectRatio < 300 {
                return CGSize(width: size.width, height: size.width / aspectRatio)
            } else {
                return CGSize(width: 300 * aspectRatio, height: 300)
            }
        } else {
            return CGSize(width: 300, height: 300)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = sizeThatFits(bounds.size)
        imageView.frame = .init(origin: .init(x: (bounds.width - size.width) / 2.0, y: 0),
                                size: size)
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        return sizeThatFits(bounds.size)
    }
}

extension UIProgressView: Placeholder {}

extension URL {
    var hashedColor: UIColor {
        let colors: [UIColor] = [
            try! UIColor(rgba_throws: "#F2EFE9"),
            try! UIColor(rgba_throws: "#904E55"),
            try! UIColor(rgba_throws: "#564E58"),
            try! UIColor(rgba_throws: "#BFB48F"),
            try! UIColor(rgba_throws: "#FFFBFF"),
            try! UIColor(rgba_throws: "#F1DABF"),
            try! UIColor(rgba_throws: "#A07178"),
            try! UIColor(rgba_throws: "#776274"),
            try! UIColor(rgba_throws: "#E6CCBE"),
            try! UIColor(rgba_throws: "#5A5353"),
        ]
//        let _h0 = hashValue
//        let _h1 = _h0.hashValue
//        let _h2 = _h1.hashValue
//        let r = CGFloat(_h0 % 256) / 256.0
//        let g = CGFloat(_h1 % 256) / 256.0
//        let b = CGFloat(_h2 % 256) / 256.0
        let hash = abs(hashValue)
        return colors[hash % colors.count]
    }
}

extension UIColor {
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}

struct ImageSizeStorage {
    private static let imageSizeDiskConfig = DiskConfig(name: "LPMetadataStorage", expiry: .never, maxSize: 10000)
    private static let imageSizeMemoryConfig = MemoryConfig(expiry: .never, countLimit: 1000, totalCostLimit: 1000)
    static let shared = ImageSizeStorage()

    private let storage = try? Cache.Storage<URL, CGSize>(
        diskConfig: imageSizeDiskConfig,
        memoryConfig: imageSizeMemoryConfig,
        transformer: TransformerFactory.forCodable(ofType: CGSize.self)
    )

    func store(size: CGSize, url: URL) {
        try? storage?.setObject(size, forKey: url, expiry: .never)
    }

    func size(for url: URL) -> CGSize? {
        try? storage?.object(forKey: url)
    }
}
