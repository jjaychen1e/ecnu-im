//
//  ContentItemsView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/28.
//

import SwiftUI

struct PostContentItemsView: View {
    @Binding var contentItems: [Any]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(zip(contentItems.indices, contentItems)), id: \.0) { _, item in
                if let item = item as? ContentItemParagraph {
                    item
                }
                if let item = item as? ContentItemBlockquote {
                    item
                }
                if let item = item as? ContentItemDivider {
                    item
                }
                if let item = item as? LinkPreviewView {
                    item
                }
                if let item = item as? ContentItemSingleImage {
                    item
                }
                if let item = item as? ContentItemImagesGrid {
                    item
                }
                if let item = item as? ContentItemCodeBlock {
                    item
                }
            }
        }
    }
}

struct PostContentView: View {
    @State var content: String
    @State var contentItems: [Any] = []

    init(content: String) {
        self.content = content
    }

    var body: some View {
        PostContentItemsView(contentItems: $contentItems)
            .onLoad {
                let parseConfiguration = ParseConfiguration(imageOnTapAction: { ImageBrowser.shared.present(imageURLs: $1, selectedImageIndex: $0) },
                                                                 imageGridDisplayMode: .narrow)
                let contentParser = ContentParser(content: content, configuration: parseConfiguration)
                let newContentItems = contentParser.parse()
                contentItems = newContentItems
            }
    }
}
