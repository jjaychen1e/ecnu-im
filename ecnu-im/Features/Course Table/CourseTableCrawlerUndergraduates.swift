//
//  CourseTableCrawlerUndergraduates.swift
//  ecnu-im
//
//  Created by Junjie Chen on 2022/8/30.
//

import Foundation
import Regex

class CourseTableCrawlerUndergraduates {
    func extractCourses(content: String) -> [Course] {
        var courses: [Course] = []

        var skippedCourseIndexList: [Int] = []
        var courseIDList: [String] = []
        var courseNameList: [String] = []
        var courseInstructorNameList: [String] = []

        /// 获取课程类别
        let regex = Regex("</a></td>\\s*?<td>(.*)?</td><td>")
        for (index, match) in regex.allMatches(in: content).enumerated() {
            if let courseType = match.captures.first, courseType == "&#30740;&#31350;&#29983;&#35838;&#31243;" {
                // 存在研究生课程，跳过
                skippedCourseIndexList.append(index)
            }
        }

        /// 获取课程代号
        let regex2 = Regex("<td>([A-Z]+[0-9]+\\..{2})</td>")
        for (index, match) in regex2.allMatches(in: content).enumerated() where !skippedCourseIndexList.contains(index) {
            if let courseIDFirstElement = match.captures.first, let courseID = courseIDFirstElement {
                courseIDList.append(courseID)
            }
        }

        /// 获取课程名称
        let regex3 = Regex("\">(.*?)</a></td>")
        for (index, match) in regex3.allMatches(in: content).enumerated() where !skippedCourseIndexList.contains(index) {
            if let courseNameFirstElement = match.captures.first, let courseName = courseNameFirstElement {
                courseNameList.append(courseName)
            }
        }

        /// 获取任课教师

        let regex4 = Regex("</td>\\t\\t<td>(.*)</td>\\r?\\n\\t\\t")
        for (index, match) in regex4.allMatches(in: content).enumerated() where !skippedCourseIndexList.contains(index) {
            if let courseInstructorNameFirstElement = match.captures.first, let courseInstructorName = courseInstructorNameFirstElement {
                courseInstructorNameList.append(courseInstructorName.replacingOccurrences(of: "<br/>", with: " "))
            }
        }

        guard courseIDList.count == courseNameList.count, courseIDList.count == courseInstructorNameList.count else {
            return courses
        }

        for i in 0 ..< courseIDList.count {
            courses.append(Course(courseID: courseIDList[i], courseName: courseNameList[i], courseInstructor: courseInstructorNameList[i]))
        }

        return courses
    }

    enum CourseTableCrawlerUndergraduatesError: Error {
        case weekStringChineseExtractionError
        case lessonTimeOffsetExtractionError
        case otherWeekOffsetExtractionError
    }

    func extractLessons(course: Course, content: String, semesterDate: Date) throws -> [Lesson] {
        var lessons: [Lesson] = []
        
        defer {
            if lessons.count == 0 {
                printDebug(course.courseName)
                DispatchQueue.main.async {
                    Toast.default(icon: .emoji("🤔"), title: course.courseName, subtitle: "未获取到开课信息，请手动检查").show()
                }
            }
        }

        let regex1 = Regex("<td>(星期.*?)</td>")
        let weekMatchResults = regex1.allMatches(in: content)
        if weekMatchResults.count == 0 {
            // e.g., 毕业实习
            return lessons
        }
        if let firstElement = weekMatchResults[0].captures.first,
           let weekLinesStr = firstElement {
            let weekLines = weekLinesStr.components(separatedBy: "<br>")
            for weekLine in weekLines {
                let weekStringChinese = weekLine.prefix(3)
                var dayOffset = 0
                if weekStringChinese == "星期一" {
                    dayOffset = 0
                } else if weekStringChinese == "星期二" {
                    dayOffset = 1
                } else if weekStringChinese == "星期三" {
                    dayOffset = 2
                } else if weekStringChinese == "星期四" {
                    dayOffset = 3
                } else if weekStringChinese == "星期五" {
                    dayOffset = 4
                } else if weekStringChinese == "星期六" {
                    dayOffset = 5
                } else if weekStringChinese == "星期日" {
                    dayOffset = 6
                } else {
                    throw CourseTableCrawlerUndergraduatesError.weekStringChineseExtractionError
                }

                let regex2 = Regex("(\\d+)-(\\d+)")
                let regex2MatchResult = regex2.firstMatch(in: weekLine)
                let lessonTimeOffsetPair = regex2MatchResult?.captures.compactMap { $0 } ?? []
                guard lessonTimeOffsetPair.count == 2,
                      let lessonTimeOffsetBegin = Int(lessonTimeOffsetPair[0]),
                      let lessonTimeOffsetEnd = Int(lessonTimeOffsetPair[1])
                else {
                    throw CourseTableCrawlerUndergraduatesError.lessonTimeOffsetExtractionError
                }

                // MARK: 课程星期偏移值

                var weekOffsetList: [Int] = []

                // 单次周的课
                let regex3 = Regex("\\[(\\d+)\\]")
                let singleWeekMatchResults = regex3.allMatches(in: weekLine)
                for singleWeekMatchResult in singleWeekMatchResults {
                    if let singleWeekMatchResultFirstElement = singleWeekMatchResult.captures.first,
                       let singleWeekMatchResult = singleWeekMatchResultFirstElement {
                        weekOffsetList.append(Int(singleWeekMatchResult)!)
                    }
                }

                let regex4 = Regex("单?双?\\[(\\d+)-(\\d+)]")
                let otherWeekMatchResults = regex4.allMatches(in: weekLine)
                for otherWeekMatchResult in otherWeekMatchResults {
                    let otherWeekOffsetPair = otherWeekMatchResult.captures.compactMap { $0 }
                    guard otherWeekOffsetPair.count == 2,
                          let otherWeekOffsetPairBegin = Int(otherWeekOffsetPair[0]),
                          let otherWeekOffsetPairEnd = Int(otherWeekOffsetPair[1])
                    else {
                        throw CourseTableCrawlerUndergraduatesError.otherWeekOffsetExtractionError
                    }

                    if otherWeekMatchResult.matchedString.first == "单" || otherWeekMatchResult.matchedString.first == "双" {
                        var skip = false
                        for weekOffset in otherWeekOffsetPairBegin ... otherWeekOffsetPairEnd {
                            if !skip {
                                weekOffsetList.append(weekOffset)
                                skip = true
                            } else {
                                skip = false
                            }
                        }
                    } else {
                        for weekOffset in otherWeekOffsetPairBegin ... otherWeekOffsetPairEnd {
                            weekOffsetList.append(weekOffset)
                        }
                    }
                }

                // MARK: Course location

                let location = weekLine.replacingAll(matching: Regex(".*\\]"), with: "")
                    .replacingOccurrences(of: ",", with: " ")
                    .trimmingCharacters(in: .whitespaces)

                let calendar = Calendar.current
                let semesterBeginDateComponents = calendar.dateComponents([.year, .month, .day], from: semesterDate)

                if let lessonBeginTimeHourMinute = LESSON_START_TIME[lessonTimeOffsetBegin],
                   let lessonEndTimeHourMinute = LESSON_END_TIME[lessonTimeOffsetEnd] {
                    var lessonBeginDateComponents = semesterBeginDateComponents
                    lessonBeginDateComponents.day! += dayOffset
                    lessonBeginDateComponents.hour = lessonBeginTimeHourMinute.0
                    lessonBeginDateComponents.minute = lessonBeginTimeHourMinute.1

                    var lessonEndDateComponents = semesterBeginDateComponents
                    lessonEndDateComponents.day! += dayOffset
                    lessonEndDateComponents.hour = lessonEndTimeHourMinute.0
                    lessonEndDateComponents.minute = lessonEndTimeHourMinute.1

                    for weekOffset in weekOffsetList {
                        let weekOffset = weekOffset - 1
                        var lessonBeginDateComponentsWithWeekOffset = lessonBeginDateComponents
                        var lessonEndDateComponentsWithWeekOffset = lessonEndDateComponents
                        lessonBeginDateComponentsWithWeekOffset.day! += weekOffset * 7
                        lessonEndDateComponentsWithWeekOffset.day! += weekOffset * 7
                        if let lessonBeginDateWithWeekOffset = calendar.date(from: lessonBeginDateComponentsWithWeekOffset),
                           let lessonEndDateWithWeekOffset = calendar.date(from: lessonEndDateComponentsWithWeekOffset) {
                            let lesson = Lesson(course: course,
                                                location: location,
                                                weekOffset: weekOffset,
                                                dayOffset: dayOffset,
                                                startTimeOffset: lessonTimeOffsetBegin,
                                                endTimeOffset: lessonTimeOffsetEnd,
                                                startDateTime: lessonBeginDateWithWeekOffset,
                                                endDateTime: lessonEndDateWithWeekOffset)
                            lessons.append(lesson)
                        }
                    }
                }
            }
        }
        return lessons
    }
}
