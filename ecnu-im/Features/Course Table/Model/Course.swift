//
//  Course.swift
//  ecnu-im
//
//  Created by Junjie Chen on 2022/8/30.
//

import Foundation

struct Course {
    let courseID: String
    let courseName: String
    let courseInstructor: String

    init(courseID: String, courseName: String, courseInstructor: String) {
        self.courseID = courseID
        self.courseName = courseName
        self.courseInstructor = courseInstructor
    }
}
