//
//  URLRequet+Post.swift
//  ecnu-im
//
//  Created by Junjie Chen on 2022/8/30.
//

import Foundation

extension URLRequest {
    private func percentEscapeString(_ string: String) -> String {
        var characterSet = CharacterSet.alphanumerics
        characterSet.insert(charactersIn: "-._* ")

        return string
            .addingPercentEncoding(withAllowedCharacters: characterSet)!
            .replacingOccurrences(of: " ", with: "+")
            .replacingOccurrences(of: " ", with: "+", options: [], range: nil)
    }

    mutating func encodeParameters(parameters: [String: String]) {
        httpMethod = "POST"

        let parameterArray = parameters.map { arg -> String in
            let (key, value) = arg
            return "\(key)=\(self.percentEscapeString(value))"
        }

        httpBody = parameterArray.joined(separator: "&").data(using: String.Encoding.utf8)
    }
}
