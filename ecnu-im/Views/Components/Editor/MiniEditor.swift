//
//  MiniEditor.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/14.
//

import SwiftUI

class EditorContentModel: ObservableObject {
    @Published var text = ""
}

struct MiniEditor: View {
    @State var discussion: FlarumDiscussion
    @ObservedObject private var model = EditorContentModel()
    @FocusState var focused: Bool

    @State var hide: () -> Void

    @EnvironmentObject var uiKitEnvironment: UIKitEnvironment
    
    var body: some View {
        Rectangle()
            .fill(ThemeManager.shared.theme.backgroundColor2)
            .frame(height: 200)
            .overlay(
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Asset.DynamicColors.dynamicBlack.swiftUIColor.opacity(0.1))
                        .frame(height: 1)

                    VStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Asset.DynamicColors.dynamicBlack.swiftUIColor.opacity(0.1), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Asset.DynamicColors.dynamicWhite.swiftUIColor)
                            )
                            .overlay(
                                TextEditor(text: $model.text)
                                    .focused($focused, equals: true)
                                    .padding(.all, 4)
                            )
                            .padding(.all, 4)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .center, spacing: 4) {
                                    Button {} label: {
                                        ZStack {
                                            Color.clear
                                            Image(systemName: "photo.fill")
                                                .font(.system(size: 20))
                                                .frame(width: 30, height: 30)
                                        }
                                    }
                                    .disabled(true)
                                    .opacity(0.3)

                                    Button {} label: {
                                        ZStack {
                                            Color.clear
                                            Text("#")
                                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                                .frame(width: 30, height: 30)
                                        }
                                    }
                                    .disabled(true)
                                    .opacity(0.3)

                                    Button {} label: {
                                        ZStack {
                                            Color.clear
                                            Text("#")
                                                .font(.system(size: 25, weight: .medium, design: .rounded))
                                                .frame(width: 30, height: 30)
                                        }
                                    }
                                    .disabled(true)
                                    .opacity(0.3)

                                    Button {} label: {
                                        ZStack {
                                            Color.clear
                                            Image(systemName: "bold")
                                                .font(.system(size: 25))
                                                .frame(width: 30, height: 30)
                                        }
                                    }
                                    .disabled(true)
                                    .opacity(0.3)

                                    Button {} label: {
                                        ZStack {
                                            Color.clear
                                            Image(systemName: "italic")
                                                .font(.system(size: 25))
                                                .frame(width: 30, height: 30)
                                        }
                                    }
                                    .disabled(true)
                                    .opacity(0.3)

                                    Button {} label: {
                                        ZStack {
                                            Color.clear
                                            Image(systemName: "underline")
                                                .font(.system(size: 25))
                                                .frame(width: 30, height: 30)
                                        }
                                    }
                                    .disabled(true)
                                    .opacity(0.3)

                                    Button {} label: {
                                        ZStack {
                                            Color.clear
                                            Image(systemName: "strikethrough")
                                                .font(.system(size: 25))
                                                .frame(width: 30, height: 30)
                                        }
                                    }
                                    .disabled(true)
                                    .opacity(0.3)

                                    Button {
                                        if let nvc = uiKitEnvironment.nvc {
                                            nvc.present(UIHostingController(rootView: EditorView(model: model)), animated: true)
                                        }
                                    } label: {
                                        ZStack {
                                            Color.clear
                                            Image(systemName: "bolt")
                                                .font(.system(size: 22))
                                                .frame(width: 30, height: 30)
                                        }
                                    }

                                    Spacer()
                                }
                            }
                            .frame(height: 30)
                            .foregroundColor(Asset.DynamicColors.dynamicBlack.swiftUIColor)

                            Button("发送") {
                                Task {
                                    if let result = try? await flarumProvider.request(.newPost(discussionID: discussion.id, content: model.text)) {
                                        model.text = ""
                                        hide()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                    .padding(.horizontal, 8)
                }
            )
            .overlay(alignment: .bottom) {
                // To fill the area...
                ThemeManager.shared.theme.backgroundColor2.frame(height: 150)
                    .offset(x: 0, y: 150)
            }
    }
}
