//
//  Debug.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/17.
//
import Foundation

// 📗
// 📘
// 📔
enum DebugLogLevel: CustomStringConvertible {
    case normal
    case warning
    case error

    var description: String {
        switch self {
        case .normal:
            return "📓"
        case .warning:
            return "📙"
        case .error:
            return "📕"
        }
    }
}

func printDebug(level: DebugLogLevel = .normal, file: String = #file, line: Int = #line, function: String = #function, _ message: CustomStringConvertible = "") {
    #if DEBUG
    print("\(level)\t[Debug log] \(URL(fileURLWithPath: file).lastPathComponent)(line \(line)), `\(function)`:\n\t[Debug log]\(message.description != "" ? " \(message)" : "")")
    #endif
}

func fatalErrorDebug(file: String = #file, line: Int = #line, function: String = #function, _ message: CustomStringConvertible = "") {
    #if DEBUG
    fatalError("\(DebugLogLevel.error)\t[Debug log] \(URL(fileURLWithPath: file).lastPathComponent)(line \(line)), `\(function)`:\n\t[Debug log]\(message.description != "" ? " \(message)" : "")")
    #endif
}

func assertDebug(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    #if DEBUG
        assert(condition(), message(), file: file, line: line)
    #endif
}

func debugExecution(_ body: () -> Void) {
    #if DEBUG
        body()
    #endif
}
