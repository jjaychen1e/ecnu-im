//
//  ECNUTextView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/8.
//

import Foundation
import UIKit

class ECNUTextView: UITextView {
    /// Disable selection while allowing href
    /// https://stackoverflow.com/a/44878203
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let pos = closestPosition(to: point) else { return false }

        guard let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left)) else { return false }

        let startIndex = offset(from: beginningOfDocument, to: range.start)

        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }
}
