//
//  ContentItemLinkPreview.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/29.
//

import AVFoundation
import Cache
import LinkPresentation
import UIKit

class ContentItemLinkPreview: UIView & ContentBlockUIView {
    var link: URL
    private var lpView: LPLinkView!

    private let metadataStorage = LPLinkMetadataStorage.shared
    var updateLayout: (() -> Void)?

    private weak var onAppearTimer: Timer?

    private func currentProperSize(boundWidth: CGFloat) -> CGSize {
        let intrinsicContentSize = lpView.intrinsicContentSize
        // Aspect ratio
        let width = min(boundWidth, 450, intrinsicContentSize.width)
        let height = width / (intrinsicContentSize.width / intrinsicContentSize.height)
        return CGSize(width: width, height: height)
    }

    private var currentSize: CGSize?

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard size.width > 0 else { return .zero }

        var returnSize: CGSize

        defer {
            currentSize = returnSize
        }

        let mappedSize: CGSize? = {
            if let cachedSize = metadataStorage.size(for: link) {
                // Keep aspect ratio
                let width = min(450, size.width, cachedSize.width)
                let height = width / (cachedSize.width / cachedSize.height)
                let finalSize = CGSize(width: width, height: height)
                return finalSize
            }
            return nil
        }()

        let nextSize = currentProperSize(boundWidth: size.width)
//        print("\(Unmanaged.passUnretained(self).toOpaque()), Next size: \(nextSize), mappedSize: \(mappedSize)")
        if mappedSize == nil || (nextSize.width > mappedSize!.width || nextSize.height > mappedSize!.height) {
            metadataStorage.store(size: nextSize, url: link)

            returnSize = nextSize
            return nextSize
        } else {
            returnSize = mappedSize!
            return mappedSize!
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let oldCurrentSize = currentSize
        let size = sizeThatFits(bounds.size)
        lpView.frame = .init(origin: .init(x: (bounds.width - size.width) / 2,
                                           y: 0),
                             size: size)
//        print("\(Unmanaged.passUnretained(self).toOpaque()), layoutSubviews: \(size)")
        if oldCurrentSize != currentSize {
//            print("\(Unmanaged.passUnretained(self).toOpaque()), updateLayout1: \(currentSize!), \(oldCurrentSize)")
            updateLayout?()
            setNeedsLayout()
//            print("\(Unmanaged.passUnretained(self).toOpaque()), updateLayout2: \(currentSize!), \(oldCurrentSize)")
        }
    }

    deinit {
        onAppearTimer?.invalidate()
        onAppearTimer = nil
    }

    private func initTimer() {
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                self.onAppearTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                    if let self = self {
                        var v: UIView = self
                        var frame = self.frame
                        while let superview = v.superview {
                            if let scrollView = superview as? UIScrollView {
                                if let tableView = superview as? UITableView,
                                   let cell = v as? UITableViewCell,
                                   tableView.visibleCells.contains(cell) {
                                    frame = self.superview!.convert(frame, to: scrollView)
                                    var screenFrame = scrollView.frame
                                    screenFrame.origin = scrollView.contentOffset
                                    if frame.intersects(screenFrame) {
//                                        print("intersect\(Unmanaged.passUnretained(self).toOpaque()), \(Unmanaged.passUnretained(scrollView).toOpaque()). \(frame), \(screenFrame)")
//                                        print("Request: \(Unmanaged.passUnretained(self).toOpaque()), link: \(self.link)")
                                        LPMetadataLoader.shared.request(url: self.link) { [weak self] metadata in
                                            if let self = self, let metadata = metadata {
                                                DispatchQueue.main.async { [weak self] in
                                                    if let self = self {
                                                        self.lpView.metadata = metadata
                                                        self.setNeedsLayout()
                                                        print("\(Unmanaged.passUnretained(self).toOpaque()), set metadata")
                                                    }
                                                }
                                            }
                                        }
                                        self.onAppearTimer?.invalidate()
                                        self.onAppearTimer = nil
                                    }
                                }
                                break
                            } else {
                                v = superview
                            }
                        }
                    }
                }
                self.onAppearTimer?.fire()
            }
        }
    }

    init(link: URL, updateLayout: (() -> Void)?) {
        self.link = link
        self.updateLayout = updateLayout

        super.init(frame: .zero)
        let lpView = LPLinkView(url: link)
        self.lpView = lpView
        addSubview(lpView)

        metadataStorage.metadata(for: link) { [weak self] metadata in
            if let self = self {
                if let metadata = metadata {
                    DispatchQueue.main.async { [weak self] in
                        if let self = self {
                            self.lpView.metadata = metadata
                            self.setNeedsLayout()
                        }
                    }
                } else {
                    self.initTimer()
                }
            }
        }
    }
}

struct LPLinkMetadataStorage {
    private static let lpLinkMetadataDiskConfig = DiskConfig(name: "LPMetadataStorage", expiry: .never, maxSize: 10000)
    private static let lpLinkPreviewSizeDiskConfig = DiskConfig(name: "LPLinkPreviewSizeStorage", expiry: .never, maxSize: 10000)
    private static let lpLinkMetadataMemoryConfig = MemoryConfig(expiry: .never, countLimit: 1000, totalCostLimit: 1000)
    private static let lpLinkPreviewSizeMemoryConfig = MemoryConfig(expiry: .never, countLimit: 1000, totalCostLimit: 1000)

    static let shared = LPLinkMetadataStorage()

    private let lpLinkMetadataStorage = try? Cache.Storage<URL, Data>(
        diskConfig: lpLinkMetadataDiskConfig,
        memoryConfig: lpLinkMetadataMemoryConfig,
        transformer: TransformerFactory.forData()
    )

    private let sizeStorage = try? Cache.Storage<URL, CGSize>(
        diskConfig: lpLinkPreviewSizeDiskConfig,
        memoryConfig: lpLinkPreviewSizeMemoryConfig,
        transformer: TransformerFactory.forCodable(ofType: CGSize.self)
    )

    func store(_ metadata: LPLinkMetadata) {
        if let storage = lpLinkMetadataStorage,
           let url = metadata.originalURL,
           let data = try? NSKeyedArchiver.archivedData(withRootObject: metadata, requiringSecureCoding: true) {
            try! storage.setObject(data, forKey: url, expiry: .never)
        }
    }

    func metadata(for url: URL) -> LPLinkMetadata? {
        guard let data = try? lpLinkMetadataStorage?.object(forKey: url) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: data)
    }

    func metadata(for url: URL, completion: @escaping (LPLinkMetadata?) -> Void) {
        lpLinkMetadataStorage?.async.object(forKey: url) { result in
            if case let .value(data) = result {
                let metadata = try? NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: data)
                completion(metadata)
            } else {
                completion(nil)
            }
        }
    }

    func store(size: CGSize, url: URL) {
        try? sizeStorage?.setObject(size, forKey: url, expiry: .never)
    }

    func size(for url: URL) -> CGSize? {
        try? sizeStorage?.object(forKey: url)
    }
}
