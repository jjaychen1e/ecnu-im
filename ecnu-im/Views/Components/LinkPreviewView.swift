//
//  LinkPreviewView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/27.
//

import LinkPresentation
import SwiftUI
import UIKit

struct LinkPreviewView: View {
    @State var link: String
    @State private var metadata: LPLinkMetadata?

    var body: some View {
        Group {
            if let metadata = metadata {
                _LinkPreviewView(metadata: metadata)
            } else {
                _LinkPreviewView(metadata: nil)
            }
        }
        .onLoad {
            Task {
                guard let url = URL(string: link) else { return }
                let metadataProvider = LPMetadataProvider()
                let metadata = try? await metadataProvider.startFetchingMetadata(for: url)
                DispatchQueue.main.async {
                    self.metadata = metadata
                }
            }
        }
    }
}

class CustomLinkView: LPLinkView {
    override var intrinsicContentSize: CGSize { CGSize(width: 0, height: super.intrinsicContentSize.height) }

    override init(url URL: URL) {
        super.init(url: URL)
    }

    override init(metadata: LPLinkMetadata) {
        super.init(metadata: metadata)
    }

    init() {
        super.init(frame: .zero)
    }
}

private struct _LinkPreviewView: UIViewRepresentable {
    typealias UIViewType = CustomLinkView
    var metadata: LPLinkMetadata?

    func makeUIView(context _: Context) -> CustomLinkView {
        guard let metadata = metadata else { return CustomLinkView() }
        let linkView = CustomLinkView(metadata: metadata)
        return linkView
    }

    func updateUIView(_: CustomLinkView, context _: Context) {}
}
