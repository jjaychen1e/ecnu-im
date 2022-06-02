//
//  CurrentValueSubject+Binding.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/6/2.
//

import Combine
import SwiftUI

extension CurrentValueSubject where Output == Bool {
    var binding: Binding<Output> {
        .init { [weak self] in
            self?.value ?? false
        } set: { [weak self] newValue in
            self?.send(newValue)
        }
    }
}

extension CurrentValueSubject where Output == BrowseCategory {
    var binding: Binding<Output> {
        .init { [weak self] in
            self?.value ?? .cards
        } set: { [weak self] newValue in
            self?.send(newValue)
        }
    }
}
