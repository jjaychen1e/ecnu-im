//
//  Array+Weak.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/6/2.
//

import Foundation

/// https://medium.com/@apstygo/implementing-weak-arrays-with-property-wrappers-in-swift-680e2b3c9fca
final class WeakObject<T: AnyObject> {
    private(set) weak var value: T?
    init(_ v: T) { value = v }
}

@propertyWrapper
struct Weak<Element> where Element: AnyObject {
    private var storage = [WeakObject<Element>]()

    var wrappedValue: [Element] {
        get { storage.compactMap { $0.value } }
        set {
            storage = newValue.map { WeakObject($0) }
        }
    }
}
