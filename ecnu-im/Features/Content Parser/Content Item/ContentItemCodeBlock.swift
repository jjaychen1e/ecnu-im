//
//  ContentItemCodeBlock.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/28.
//

import SwiftUI

struct ContentItemCodeBlock: View {
    @State var text: NSAttributedString
    @State var textHeight: CGFloat = 0

    var body: some View {
        DynamicHeightTextView(text: $text, height: $textHeight)
            .frame(height: textHeight)
            .padding(.all, 4)
            .background(Color.primary.opacity(0.1))
    }
}
