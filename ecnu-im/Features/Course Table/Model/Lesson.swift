//
//  Lesson.swift
//  ecnu-im
//
//  Created by Junjie Chen on 2022/8/30.
//

import Foundation

struct Lesson {
    let courseID: String
    let courseName: String
    let location: String
    let courseInstructor: String
    let weekOffset: Int
    let dayOffset: Int
    let startTimeOffset: Int
    let endTimeOffset: Int
    let startDateTime: Date
    let endDateTime: Date
    
    init(course: Course, location: String, weekOffset: Int, dayOffset: Int, startTimeOffset: Int, endTimeOffset: Int, startDateTime: Date, endDateTime: Date) {
        courseID = course.courseID
        courseName = course.courseName
        courseInstructor = course.courseInstructor
        self.location = location
        self.weekOffset = weekOffset
        self.dayOffset = dayOffset
        self.startTimeOffset = startTimeOffset
        self.endTimeOffset = endTimeOffset
        self.startDateTime = startDateTime
        self.endDateTime = endDateTime
    }
}
