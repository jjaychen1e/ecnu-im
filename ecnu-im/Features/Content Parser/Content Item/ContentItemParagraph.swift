//
//  ContentItemParagraph.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/28.
//

import Foundation
import SwiftUI

struct ContentItemParagraph: View {
    @State var text: NSAttributedString
    @State var textHeight: CGFloat = 0

    var body: some View {
        DynamicHeightTextView(text: $text, height: $textHeight)
            .frame(height: textHeight)
    }
}
