//
//  FlarumAPIErrorModel.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/23.
//

import Foundation

struct FlarumAPIErrorDetail: Decodable {
    let status: String
    let code: String
    let detail: String?
}

struct FlarumAPIErrorModel: Decodable {
    let errors: [FlarumAPIErrorDetail]
}
