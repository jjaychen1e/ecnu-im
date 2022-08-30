//
//  Date+WeekDay.swift
//  ecnu-im
//
//  Created by Junjie Chen on 2022/8/30.
//

import Foundation
extension Date {
    enum WeekDay: Int {
        case sunday = 1
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday
    }

    func getWeekDay() -> WeekDay {
        let calendar = Calendar.current
        let weekDay = calendar.component(Calendar.Component.weekday, from: self)
        return WeekDay(rawValue: weekDay)!
    }
}
