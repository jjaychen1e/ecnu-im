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
        let jsonDecoder = JSONDecoder()
        if let data = try? rawData() {
            return try? jsonDecoder.decode(type, from: data)
        }
        return nil
    }
}
