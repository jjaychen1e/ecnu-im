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
}
