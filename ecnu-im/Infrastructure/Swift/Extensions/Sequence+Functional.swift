//
//  Sequence+Functional.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/11.
//

import Foundation

// https://gist.github.com/florianpircher/928062b345a5c84ed421dc6b39cc8ea2
extension Sequence {
    func unique<T: Hashable>(by taggingHandler: (_ element: Self.Iterator.Element) -> T) -> [Self.Iterator.Element] {
        var knownTags = Set<T>()

        return filter { element -> Bool in
            let tag = taggingHandler(element)

            if !knownTags.contains(tag) {
                knownTags.insert(tag)
                return true
            }

            return false
        }
    }
}
