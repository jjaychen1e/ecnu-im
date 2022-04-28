//
//  ParseConfiguration.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/28.
//

import Foundation

struct ParseConfiguration {
    var imageOnTapAction: (Int, [URL]) -> Void

    enum ImageGridDisplayMode {
        case wide
        case narrow
    }

    var imageGridDisplayMode: ImageGridDisplayMode
}
