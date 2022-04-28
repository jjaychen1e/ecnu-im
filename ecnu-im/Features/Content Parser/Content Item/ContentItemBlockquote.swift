//
//  ContentItemBlockquote.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/28.
//

import Foundation
import SwiftUI

struct ContentItemBlockquote: View {
    @State var contentItems: [Any] = []
    
    var body: some View {
        PostContentItemsView(contentItems: $contentItems)
            .padding(.leading, 8)
            .background(
                HStack {
                    Color.blue.opacity(0.3)
                        .frame(width: 5)
                    Spacer()
                }
            )
    }
}
