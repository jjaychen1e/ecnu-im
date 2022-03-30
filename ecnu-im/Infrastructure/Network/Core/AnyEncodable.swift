//
//  AnyEncodable.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/26.
//

import Foundation
struct AnyEncodable: Encodable {
    private let encodable: Encodable

    public init(_ encodable: Encodable) {
        self.encodable = encodable
    }

    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
