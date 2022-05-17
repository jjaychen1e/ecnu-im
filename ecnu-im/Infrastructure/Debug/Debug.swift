//
//  Debug.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/17.
//

func fatalErrorDebug(file: String = #file, line: Int = #line, function: String = #function, _ message: String = "") {
    #if DEBUG
        fatalError("\(file)(line \(line)): \(function).\(message != "" ? " \(message)" : "")")
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
