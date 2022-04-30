//
//  ContentItemLinkPreview.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/29.
//

import LinkPresentation
import RxSwift
import UIKit

class ContentItemLinkPreview: UIView {
    var link: URL
    private var lpView: LPLinkView!

    private var provider: LPMetadataProvider?
    private let metadataStorage = MetadataStorage()

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var restrictHeight: CGFloat? {
        if let host = link.host {
            let whiteLists230: [String] = [
                "bilibili.com",
                "b23.tv",
                "youtube.com",
                "youtu.be",
                "music.163.com",
                "y.qq.com",
                "v.qq.com",
            ]

            if whiteLists230.first(where: { url in host.contains(url) }) != nil {
                return 230
            }

            let whiteList500: [String] = [
                "xiaoyuzhoufm.com",
                "apple.com",
            ]

            if whiteList500.first(where: { url in host.contains(url) }) != nil {
                return 500
            }
        }

        return 50
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let lpView = lpView {
            let threshold: CGFloat = 450
            if frame.size.width > threshold {
                lpView.snp.remakeConstraints { make in
                    make.top.bottom.equalToSuperview()
                    make.centerX.equalToSuperview()
                    make.width.equalTo(threshold)
                    if let restrictHeight = restrictHeight {
                        make.height.lessThanOrEqualTo(restrictHeight)
                    }
                }
            } else {
                lpView.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                    if let restrictHeight = restrictHeight {
                        make.height.lessThanOrEqualTo(restrictHeight)
                    }
                }
            }
        }
    }

    init(link: URL) {
        self.link = link
        super.init(frame: .zero)
        let dumbView = UIView()
        addSubview(dumbView)
        dumbView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let lpView = LPLinkView(url: link)
        self.lpView = lpView
        dumbView.addSubview(lpView)
        lpView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            if let restrictHeight = restrictHeight {
                make.height.lessThanOrEqualTo(restrictHeight)
            }
        }

        Task {
            if let metadata = metadataStorage.metadata(for: link) {
                lpView.metadata = metadata
            } else {
                let metadataProvider = LPMetadataProvider()
                self.provider = metadataProvider
                if let metadata = try? await metadataProvider.startFetchingMetadata(for: link) {
                    lpView.metadata = metadata
                    setNeedsLayout()
                    metadataStorage.store(metadata)
                }
            }
        }
    }

    deinit {
        provider?.cancel()
    }
}

struct MetadataStorage {
    private let storage = UserDefaults.standard
    func store(_ metadata: LPLinkMetadata) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: metadata, requiringSecureCoding: true)
            var metadatas = storage.dictionary(forKey: "Metadata") as? [String: Data] ?? [String: Data]()
            while metadatas.count > 200 {
                metadatas.removeValue(forKey: metadatas.randomElement()!.key)
            }
            metadatas[metadata.originalURL!.absoluteString] = data
            storage.set(metadatas, forKey: "Metadata")
        } catch {
            print("Failed storing metadata with error \(error as NSError)")
        }
    }

    func metadata(for url: URL) -> LPLinkMetadata? {
        guard let metadatas = storage.dictionary(forKey: "Metadata") as? [String: Data] else { return nil }
        guard let data = metadatas[url.absoluteString] else { return nil }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: data)
        } catch {
            print("Failed to unarchive metadata with error \(error as NSError)")
            return nil
        }
    }
}
