//
//  URL+Network+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/26.
//

import Foundation

extension URL {
    init<T: TargetType>(target: T) {
        let targetPath = target.path
        if targetPath.isEmpty {
            self = target.baseURL
        } else {
            self = target.baseURL.appendingPathComponent(targetPath)
        }
    }
}
