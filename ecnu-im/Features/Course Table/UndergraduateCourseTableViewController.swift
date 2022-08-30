//
//  UndergraduateCourseTableViewController.swift
//  ecnu-im
//
//  Created by Junjie Chen on 2022/8/30.
//

import Foundation
import Regex
import UIKit
import WebController
import WebKit

class UndergraduateCourseTableViewController: CommonWebViewController {
    private var semesterDate: Date

    init(semesterDate: Date) {
        self.semesterDate = semesterDate

        let url = URL(string: "http://portal1.ecnu.edu.cn/cas/login?service=https://applicationnewjw.ecnu.edu.cn/eams/home.action")
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

    @objc
    func exportCourseTable() {
        Task {
            guard await startExtracting() else { return }
            let cookies = await self.webController.webView.getCookies()
            var found: Bool = false
            for cookie in cookies {
                if cookie.name == "JSESSIONID", let cookie = HTTPCookie(properties: [
                    HTTPCookiePropertyKey.domain: "applicationnewjw.ecnu.edu.cn",
                    HTTPCookiePropertyKey.path: "/eams",
                    HTTPCookiePropertyKey.name: "JSESSIONID",
                    HTTPCookiePropertyKey.value: cookie.value,
                ]) {
                    HTTPCookieStorage.shared.setCookie(cookie)
                    found = true
                    break
                }
            }

            guard found else {
                Toast.default(icon: .emoji("‼️"), title: "未检测到登录状态").show()
                await finishExtracting()
                return
            }

            if let result = try? await webController.webView.evaluateJavaScript("document.body.innerHTML"),
               let content = result as? String {
                let regex = Regex("name=\"semester\\.id\" value=\"(\\d+)\"")
                if let firstElement = regex.firstMatch(in: content)?.captures.first,
                   let semesterID = firstElement {
                    let crawler = CourseTableCrawlerUndergraduates()
                    let courses = crawler.extractCourses(content: content)
                    guard courses.count > 0 else {
                        Toast.default(icon: .emoji("‼️"), title: "未提取到课表信息", subtitle: "请打开我的课表并选择对应学期").show()
                        await finishExtracting()
                        return
                    }
                    await withTaskGroup(of: [Lesson].self) { group in
                        for course in courses {
                            group.addTask {
                                let postData = [
                                    "lesson.semester.id": semesterID,
                                    "lesson.no": course.courseID,
                                ]

                                var request = URLRequest(url: URL(string: "https://applicationnewjw.ecnu.edu.cn/eams/publicSearch!search.action")!)
                                request.encodeParameters(parameters: postData)
                                guard let (data, _) = try? await URLSession.shared.data(for: request),
                                      let content = String(data: data, encoding: .utf8) else {
                                    return []
                                }

                                return (try? crawler.extractLessons(course: course, content: content, semesterDate: await self.semesterDate)) ?? []
                            }
                        }

                        var lessons: [Lesson] = []
                        for await _lessons in group {
                            lessons.append(contentsOf: _lessons)
                        }

                        guard lessons.count > 0 else {
                            Toast.default(icon: .emoji("‼️"), title: "未提取到开课信息", subtitle: "请重试").show()
                            await finishExtracting()
                            return
                        }

                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let semesterDateString = dateFormatter.string(from: semesterDate)
                        CalendarCenter.shared.saveEvent(for: lessons, in: "\(semesterDateString) 学期课程表")
                    }
                    await finishExtracting()
                    return
                } else {
                    Toast.default(icon: .emoji("‼️"), title: "未提取到学期信息", subtitle: "请打开我的课表并选择对应学期").show()
                    await finishExtracting()
                    return
                }
            } else {
                Toast.default(icon: .emoji("‼️"), title: "未提取到网页 HTML").show()
                await finishExtracting()
                return
            }
        }
    }
}
