//
//  ContentItemNode.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/2.
//

import Foundation

protocol ContentItemNode {
    var id: Int { get set }
    func convertToView() -> ContentBlockUIView
}
