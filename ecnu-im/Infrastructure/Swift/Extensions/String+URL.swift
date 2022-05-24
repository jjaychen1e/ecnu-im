//
//  String+URL.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/21.
//

import Foundation

extension String {
    var url: URL? {
        URL(string: self)
    }
}
