//
//  CalendarCenter.swift
//  ecnu-im
//
//  Created by Junjie Chen on 2022/8/30.
//

import EventKit
import UIKit

class CalendarCenter {
    static let shared = CalendarCenter()

    let eventStore = EKEventStore()

    func courseCalendar(title: String) -> EKCalendar? {
        if let calendar = eventStore.calendars(for: .event).filter({ $0.title == title }).first {
            return calendar
        }
        return createNewCalendar(withName: title)
    }

    func bestPossibleEKSource() -> EKSource? {
        let `default` = eventStore.defaultCalendarForNewEvents?.source
        let iCloud = eventStore.sources.first(where: { $0.title == "iCloud" }) // this is fragile, user can rename the source
        let local = eventStore.sources.first(where: { $0.sourceType == .local })

        return `default` ?? iCloud ?? local
    }

    func createNewCalendar(withName name: String) -> EKCalendar? {
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = name
        calendar.cgColor = UIColor.purple.cgColor

        guard let source = bestPossibleEKSource() else {
            return nil
        }
        calendar.source = source
        try! eventStore.saveCalendar(calendar, commit: true)
        return calendar
    }

    func getCalendarAccessPermission(action: @escaping () -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { success, error in
                guard success else {
                    Toast.default(icon: .emoji("🙀"), title: "获得日历访问权限失败").show()
                    return
                }

                action()
            }
        } else {
            eventStore.requestAccess(to: .event) { success, error in
                guard success else {
                    Toast.default(icon: .emoji("🙀"), title: "获得日历访问权限失败").show()
                    return
                }

                action()
            }
        }
    }

    func saveEvent(for lessons: [Lesson], in calendarTitle: String) {
        getCalendarAccessPermission {
            if let courseCalendar = self.courseCalendar(title: calendarTitle) {
                for lesson in lessons {
                    let event: EKEvent = .init(eventStore: self.eventStore)
                    event.title = lesson.courseName
                    event.startDate = lesson.startDateTime
                    event.endDate = lesson.endDateTime
                    event.location = lesson.location
                    event.notes = lesson.courseInstructor + ", \(lesson.location)"
                    event.calendar = courseCalendar
                    try? self.eventStore.save(event, span: .thisEvent, commit: false)
                }
                try? self.eventStore.commit()
                if let url = URL(string: "calshow://") {
                    DispatchQueue.main.async {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }
        }
    }
}
