//
//  UserDefaluts+JSON+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/28.
//

import Foundation
import SwiftyJSON

// TODO: Tag 会丢非 CodingKey 里的东西吗？

extension UserDefaults {
    func setEncodable<T: Encodable>(_ value: T, forKey key: String) {
        if let jsonData = try? JSONEncoder().encode(value) {
            set(jsonData, forKey: key)
        }
    }

    func object<T: Decodable>(forKey key: String, type _: T.Type) -> T? {
        if let jsonData = object(forKey: key) as? Data,
           let decodedResult = try? JSONDecoder().decode(T.self, from: jsonData) {
            return decodedResult
        }
        return nil
    }
}
