//
//  String+Network+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/26.
//

import Foundation

extension String {
    var urlEscaped: String {
        self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
}
