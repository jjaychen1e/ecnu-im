//
//  UserDefaults+DefaultValue.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/6/1.
//

import Foundation

extension UserDefaults {
    func optionalInt(forKey defaultName: String) -> Int? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Int
        }
        return nil
    }

    func optionalBool(forKey defaultName: String) -> Bool? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Bool
        }
        return nil
    }

    func setDefaultValuesForKeys(_ keyedValues: [String: Any]) {
        let filteredKeyedValues = keyedValues.filter { value(forKey: $0.key) == nil }
        setValuesForKeys(filteredKeyedValues)
    }
}
