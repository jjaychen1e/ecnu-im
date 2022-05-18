//
//  FlarumProfileAnswer.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/18.
//

import Foundation

struct FlarumProfileAnswerAttributes: Codable {
    struct Field: Codable {
        var name: String
        var description: String
        var required: Bool
        var validation: String
        var prefix: String
        var icon: String?
        var sort: Int
        var on_bio: Bool
        var type: FieldType
        var deleted_at: String?

        enum FieldType: String, RawRepresentable, Codable {
            case select
        }
    }

    var user_id: Int
    var content: String
    var field: Field
    var fieldId: Int
}

class FlarumProfileAnswer: Codable {
    init(id: String, attributes: FlarumProfileAnswerAttributes) {
        self.id = id
        self.attributes = attributes
    }

    var id: String
    var attributes: FlarumProfileAnswerAttributes
}

extension FlarumProfileAnswer: Hashable {
    static func == (lhs: FlarumProfileAnswer, rhs: FlarumProfileAnswer) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
