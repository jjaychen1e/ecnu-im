//
//  DynamicHeightTextView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/28.
//

import Foundation
import SwiftUI
import UIKit

struct DynamicHeightTextView: UIViewRepresentable {
    @Binding var text: NSAttributedString
    @Binding var height: CGFloat

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()

        textView.isEditable = false
        textView.isUserInteractionEnabled = true

        textView.attributedText = text
        textView.backgroundColor = UIColor.clear

        context.coordinator.textView = textView
        textView.delegate = context.coordinator
        textView.layoutManager.delegate = context.coordinator

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = text
        uiView.panGestureRecognizer.isEnabled = false
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(dynamicSizeTextField: self)
    }

    class Coordinator: NSObject, UITextViewDelegate, NSLayoutManagerDelegate {
        var dynamicHeightTextView: DynamicHeightTextView

        weak var textView: UITextView?

        init(dynamicSizeTextField: DynamicHeightTextView) {
            dynamicHeightTextView = dynamicSizeTextField
        }

        func textViewDidChange(_ textView: UITextView) {
            dynamicHeightTextView.text = textView.attributedText
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                textView.resignFirstResponder()
                return false
            }
            return true
        }

        func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
            DispatchQueue.main.async { [weak self] in
                guard let textView = self?.textView, let self = self else {
                    return
                }

                let size = textView.sizeThatFits(textView.bounds.size)
                if self.dynamicHeightTextView.height != size.height {
                    self.dynamicHeightTextView.height = size.height
                }
            }
        }
    }
}
