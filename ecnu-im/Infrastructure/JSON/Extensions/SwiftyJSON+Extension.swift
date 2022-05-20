//
//  SwiftyJSON+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/31.
//

import Foundation
import SwiftyJSON

extension JSON {
    func removing(key: String) -> JSON {
        var dic = dictionaryValue
        dic.removeValue(forKey: key)
        return JSON(dic)
    }

    func decode<T>(_ type: T.Type) -> T? where T: Decodable {
        if let data = try? rawData() {
            #if DEBUG
                do {
                    return try JSONDecoder().decode(type, from: data)
                } catch {
                    print(String(data: data, encoding: .utf8) ?? "Failed to parse.")
                    _ = try! JSONDecoder().decode(type, from: data)
                }
            #else
                return try? JSONDecoder().decode(type, from: data)
            #endif
        }
        return nil
    }
}
