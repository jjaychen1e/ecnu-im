//
//  Date+Description+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/27.
//

import Foundation

extension Date {
    var localeDescription: String {
        let timeDifference = -timeIntervalSinceNow
        if timeDifference < 60 * 60 {
            // Less than an hour
            return "\(Int(timeDifference / 60 + 0.5)) 分钟前"
        } else if timeDifference < 60 * 60 * 24 {
            // Less than one day
            return "\(Int(timeDifference / 60 / 60 + 0.5)) 小时前"
        } else if timeDifference < 60 * 60 * 24 * 7 {
            // Less than one week
            return "\(Int(timeDifference / 60 / 60 / 24 + 0.5)) 天前"
        } else {
            // yyyy-MM-dd
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: self)
        }
        
    }
}
