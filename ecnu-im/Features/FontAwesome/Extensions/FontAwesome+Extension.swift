//
//  FontAwesome+Extension.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/28.
//

import FontAwesome
import Foundation
import SwiftUI

extension Image {
    init(fa: FontAwesome, faStyle: FontAwesomeStyle, color: Color = .primary, size: CGSize = .init(width: 40, height: 40)) {
        self.init(uiImage: UIImage.fontAwesomeIcon(name: fa, style: faStyle, textColor: UIColor(color), size: size))
    }
}

extension Text {
    init(fa: FontAwesome, faStyle: FontAwesomeStyle, size: CGFloat = 17) {
        self = Text(String.fontAwesomeIcon(name: fa))
            .font(.init(uiFont: UIFont.fontAwesome(ofSize: size, style: faStyle)))
    }
}

extension SwiftUI.Font {
    init(uiFont: UIFont) {
        self = SwiftUI.Font(uiFont as CTFont)
    }
}
