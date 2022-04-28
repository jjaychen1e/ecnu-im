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
        let gridLayout: [GridItem] = {
            if configuration.imageGridDisplayMode == .wide || urls.count > 4 {
                return Array(repeating: .init(.flexible()), count: 3)
            } else {
                return Array(repeating: .init(.flexible()), count: 2)
            }
        }()

        // https://stackoverflow.com/a/64252041
        LazyVGrid(columns: gridLayout, alignment: .center, spacing: 10) {
            ForEach(0 ..< urls.count, id: \.self) { i in
                ParsedGridImageView(urls: urls, index: i, onTapAction: configuration.imageOnTapAction)
            }
        }
    }
}
