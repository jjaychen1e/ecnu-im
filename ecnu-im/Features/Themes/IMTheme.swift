//
//  IMTheme.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/2.
//

import Foundation
import SwiftUI

protocol IMTheme {
    var textColor: Color { get set }
    var backgroundColor1: Color { get set }
    var backgroundColor2: Color { get set }
    var cardColor: Color { get set }
    var mentionColor: Color { get set }
    var linkTextColor: Color { get set }
    var primaryText: Color { get set }
    var secondaryText: Color { get set }
}
