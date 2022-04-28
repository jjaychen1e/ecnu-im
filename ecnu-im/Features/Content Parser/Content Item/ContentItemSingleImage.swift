//
//  ContentItemSingleImage.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/28.
//

import SwiftUI
import Kingfisher

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
