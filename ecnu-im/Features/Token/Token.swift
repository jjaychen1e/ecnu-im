//
//  Token.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/26.
//

import Foundation

struct Token: Codable {
    let token: String
    let userId: Int

    private static var store: Token?

    private static let userDefaultsKey = "Token"

    func persist() {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        Self.store = self
    }

    @discardableResult
    static func persistedToken() -> Token? {
        if let store = store {
            return store
        } else {
            let decoder = JSONDecoder()
            if let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey),
               let token = try? decoder.decode(Token.self, from: data) {
                store = token
                return token
            }
            return nil
        }
    }
}
