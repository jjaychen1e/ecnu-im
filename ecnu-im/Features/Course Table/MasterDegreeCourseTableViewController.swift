//
//  MasterDegreeCourseTableViewController.swift
//  ecnu-im
//
//  Created by Junjie Chen on 2022/8/30.
//

import Foundation
import Regex
import UIKit
import WebController
import WebKit

class MasterDegreeCourseTableViewController: CommonWebViewController {
    private var semesterDate: Date

    init(semesterDate: Date) {
        self.semesterDate = semesterDate

        let url = URL(string: "http://portal1.ecnu.edu.cn/cas/login?service=http://applicationgsis.ecnu.edu.cn/gsis/sis/gsis/fw/xsfw/index.jsp")
        super.init(url: url!)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        webController.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "提取", style: .done, target: self, action: #selector(exportCourseTable)),
        ]

        webController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "退出", style: .done, target: self, action: #selector(done))
    }

    func webController(_ webController: WebController, navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.request.value(forHTTPHeaderField: "Accept-Language") != "zh-CN", navigationAction.navigationType != .other else {
            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)

        var request = navigationAction.request
        request.setValue("zh-CN", forHTTPHeaderField: "Accept-Language")
        webController.webView.load(request)
    }

    private var isExtracting = false

    private func startExtracting() async -> Bool {
        await MainActor.run {
            if isExtracting {
                return false
            }
            isExtracting = true
            webController.navigationItem.rightBarButtonItem?.isEnabled = false
            Toast.default(icon: .emoji("🤖"), title: "正在尝试提取课表").show()
            return true
        }
    }

    private func finishExtracting() async {
        await MainActor.run {
            self.isExtracting = false
            webController.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }

    enum MasterDegreeCourseTableViewControllerError: Error {
        case weekStringChineseExtractionError
    }

    @objc
    func exportCourseTable() {
        Task {
            guard await startExtracting() else { return }

            if let result = try? await webController.webView.evaluateJavaScript("document.body.innerHTML"),
               let content = result as? String
            {
                print(content)
                let regexCourseName = Regex("ng-bind-html=\"x\\.title\"(.*?\n*?)*>(.*?)</td>")
                let courseNames = regexCourseName.allMatches(in: content).compactMap { $0.captures[1] }
                
                let regexInstructorName = Regex("ng-bind-html=\"x\\.staffname\"(.*?\n*?)*>(.*?)</td>")
                let instructorNames = regexInstructorName.allMatches(in: content).compactMap { $0.captures[1] }
                
                let regexCourseDescription = Regex("ng-bind-html=\"x\\.classOpenDescription\"(.*?\n*?)*>(.*?)</td>")
                let courseDescriptions = regexCourseDescription.allMatches(in: content).compactMap { $0.captures[1] }
                
                let courseCount = courseNames.count

                guard courseNames.count == instructorNames.count, courseNames.count == courseDescriptions.count else {
                    Toast.default(icon: .emoji("‼️"), title: "提取信息不一致", subtitle: "请联系管理员反馈问题").show()
                    await finishExtracting()
                    return
                }

                guard courseCount != 0 else {
                    Toast.default(icon: .emoji("‼️"), title: "未提取到学期信息", subtitle: "请打开我的课表并选择对应学期").show()
                    await finishExtracting()
                    return
                }

                var lessons: [Lesson] = []

                for i in 0 ..< courseCount {
                    let description = String(courseDescriptions[i])
                    let regex = Regex("(\\d+?)-(\\d+?)周，每周(.{3})，(\\d+?)-(\\d+?)节，地点：(.*?)；")
                    let matchResults = regex.allMatches(in: description)
                    for matchResult in matchResults {
                        if let weekOffsetStartStr = matchResult.captures[safe: 0]?.map({ $0 }),
                           let weekOffsetEndStr = matchResult.captures[safe: 1]?.map({ $0 }),
                           let weekOffsetStart = Int(weekOffsetStartStr),
                           let weekOffsetEnd = Int(weekOffsetEndStr),
                           let weekdayString = matchResult.captures[safe: 2]?.map({ $0 }),
                           let lessonTimeOffsetStartStr = matchResult.captures[safe: 3]?.map({ $0 }),
                           let lessonTimeOffsetEndStr = matchResult.captures[safe: 4]?.map({ $0 }),
                           let lessonTimeOffsetStart = Int(lessonTimeOffsetStartStr),
                           let lessonTimeOffsetEnd = Int(lessonTimeOffsetEndStr),
                           let locationString = matchResult.captures[safe: 5]?.map({ $0 })
                        {
                            var dayOffset = 0
                            if weekdayString == "星期一" {
                                dayOffset = 0
                            } else if weekdayString == "星期二" {
                                dayOffset = 1
                            } else if weekdayString == "星期三" {
                                dayOffset = 2
                            } else if weekdayString == "星期四" {
                                dayOffset = 3
                            } else if weekdayString == "星期五" {
                                dayOffset = 4
                            } else if weekdayString == "星期六" {
                                dayOffset = 5
                            } else if weekdayString == "星期天" {
                                dayOffset = 6
                            } else {
                                throw MasterDegreeCourseTableViewControllerError.weekStringChineseExtractionError
                            }

                            let calendar = Calendar.current
                            let semesterBeginDateComponents = calendar.dateComponents([.year, .month, .day], from: semesterDate)

                            if let lessonBeginTimeHourMinute = LESSON_START_TIME[lessonTimeOffsetStart],
                               let lessonEndTimeHourMinute = LESSON_END_TIME[lessonTimeOffsetEnd]
                            {
                                var lessonBeginDateComponents = semesterBeginDateComponents
                                lessonBeginDateComponents.day! += dayOffset
                                lessonBeginDateComponents.hour = lessonBeginTimeHourMinute.0
                                lessonBeginDateComponents.minute = lessonBeginTimeHourMinute.1

                                var lessonEndDateComponents = semesterBeginDateComponents
                                lessonEndDateComponents.day! += dayOffset
                                lessonEndDateComponents.hour = lessonEndTimeHourMinute.0
                                lessonEndDateComponents.minute = lessonEndTimeHourMinute.1

                                for weekOffset in weekOffsetStart ... weekOffsetEnd {
                                    let weekOffset = weekOffset - 1
                                    var lessonBeginDateComponentsWithWeekOffset = lessonBeginDateComponents
                                    var lessonEndDateComponentsWithWeekOffset = lessonEndDateComponents
                                    lessonBeginDateComponentsWithWeekOffset.day! += weekOffset * 7
                                    lessonEndDateComponentsWithWeekOffset.day! += weekOffset * 7
                                    if let lessonBeginDateWithWeekOffset = calendar.date(from: lessonBeginDateComponentsWithWeekOffset),
                                       let lessonEndDateWithWeekOffset = calendar.date(from: lessonEndDateComponentsWithWeekOffset)
                                    {
                                        let lesson = Lesson(course: Course(courseID: "",
                                                                           courseName: courseNames[i],
                                                                           courseInstructor: instructorNames[i]),
                                                            location: locationString,
                                                            weekOffset: weekOffset,
                                                            dayOffset: dayOffset,
                                                            startTimeOffset: lessonTimeOffsetStart,
                                                            endTimeOffset: lessonTimeOffsetEnd,
                                                            startDateTime: lessonBeginDateWithWeekOffset,
                                                            endDateTime: lessonEndDateWithWeekOffset)
                                        lessons.append(lesson)
                                    }
                                }
                            }
                        }
                    }
                }

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let semesterDateString = dateFormatter.string(from: semesterDate)
                CalendarCenter.shared.saveEvent(for: lessons, in: "\(semesterDateString) 学期课程表")
                await finishExtracting()
                return
            } else {
                Toast.default(icon: .emoji("‼️"), title: "未提取到网页 HTML").show()
                await finishExtracting()
                return
            }
        }
    }
}
