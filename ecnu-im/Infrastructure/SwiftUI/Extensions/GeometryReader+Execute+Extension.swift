//
//  GeometryReader+Execute+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/27.
//

import Foundation
import SwiftUI

extension View {
    func execute(closure: () -> Void) -> some View {
        closure()
        return self.background(Color.clear.opacity(0))
    }

    func executeAsync(closure: @escaping () -> Void) -> some View {
        DispatchQueue.main.async {
            closure()
        }
        return self.background(Color.clear.opacity(0))
    }
}
