//
//  Array+Safe.swift
//  ecnu-im
//
//  Created by Junjie Chen on 2022/8/30.
//

import Foundation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
