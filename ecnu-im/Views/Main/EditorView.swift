//
//  EditorView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/12.
//

import SwiftUI
// import Markdown

struct EditorView: View {
    @ObservedObject var model: EditorContentModel

    var body: some View {
        SwiftDownEditor(text: $model.text)
            .insetsSize(40)
            .theme(Theme.BuiltIn.defaultDark.theme())
            .edgesIgnoringSafeArea(.all)
    }
}

struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView(model: .init())
    }
}
