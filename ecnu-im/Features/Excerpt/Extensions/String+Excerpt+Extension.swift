//
//  String+Excerpt+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/27.
//

import Foundation

extension String {
    var htmlToAttributedString: AttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            let nsAttributedString = try NSAttributedString(data: data, options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ],
            documentAttributes: nil)
            return AttributedString(nsAttributedString)
        } catch {
            return nil
        }
    }
}
