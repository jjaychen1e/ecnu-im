//
//  ContentHtmlParser.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/27.
//

import Foundation
import SwiftSoup

class ContentHtmlParser {
    func parse(_ contentHtml: String) -> Elements? {
        do {
            let doc = try SwiftSoup.parse(contentHtml)
            if let body = doc.body() {
                let children = body.children()
                return children
            }
        } catch let Exception.Error(_, message) {
            print(message)
        } catch {
            print("error")
        }
        
        return nil
    }
}
