//
//  ContentItemParagraphNode.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/2.
//

import Foundation

struct ContentItemParagraphNode: ContentItemNode {
    var id: Int
    var attributedString: NSAttributedString
    
    func convertToView() -> ContentBlockUIView {
        ContentItemParagraphUIView(attributedText: attributedString)
    }
}
