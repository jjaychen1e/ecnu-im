//
//  ImageBrowser.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/31.
//

import Lightbox
import UIKit

class ImageBrowser {
    private var imageURLs: [URL] = []
    private var startedIndex: Int = 0

    static let shared = ImageBrowser()

    func present(imageURLs: [URL], selectedImageIndex: Int? = nil) {
        self.imageURLs = imageURLs
        startedIndex = selectedImageIndex ?? 0
        let images = imageURLs.map { LightboxImage(imageURL: $0) }
        let controller = LightboxController(images: images, startIndex: startedIndex)
        controller.dynamicBackground = true
        controller.modalPresentationStyle = .fullScreen
        UIApplication.shared.topController()?.present(controller, animated: true)
    }
}
