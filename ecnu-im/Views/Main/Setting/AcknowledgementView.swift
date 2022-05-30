//
//  AcknowledgementView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/30.
//

import SwiftUI

private struct HrefLabel: View {
    @State var href: String
    @State var text: String

    var body: some View {
        Button(action: {
            if let url = URL(string: URLService.link(href: href).url) {
                UIApplication.shared.open(url)
            }
        }, label: {
            HStack {
                Text(text)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
            }
            .background(Color.primary.opacity(0.0001))
        })
    }
}

struct AcknowledgementView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    HrefLabel(href: "https://github.com/JJAYCHEN1e", text: "@jjaychen")
                } header: {
                    Text("开发者")
                } footer: {
                    Text("参与本项目开发的人员。排名不分先后。")
                }

                Section {
                    Group {
                        HrefLabel(href: "https://github.com/Alamofire/Alamofire", text: "@Alamofire/Alamofire")
                        HrefLabel(href: "https://github.com/SwiftyJSON/SwiftyJSON", text: "@SwiftJSON/SwiftyJSON")
                        HrefLabel(href: "https://github.com/yeahdongcn/UIColor-Hex-Swift", text: "@yeahdongcn/UIColor-Hex-Swift")
                        HrefLabel(href: "https://github.com/thii/FontAwesome.swift", text: "@thii/FontAwesome")
                        HrefLabel(href: "https://github.com/onevcat/Kingfisher", text: "@onevcat/Kingfisher")
                        HrefLabel(href: "https://github.com/globulus/swiftui-pull-to-refresh", text: "@globulus/swiftui-pull-to-refresh")
                        HrefLabel(href: "https://github.com/sharplet/Regex", text: "@sharplet/Regex")
                        HrefLabel(href: "https://github.com/SnapKit/SnapKit", text: "@SnapKit/SnapKit")
                        HrefLabel(href: "https://github.com/objecthub/swift-markdownkit", text: "@objecthub/swift-markdownkit")
                        HrefLabel(href: "https://github.com/johnxnguyen/Down", text: "@johnxnguyen/Down")
                    }
                    Group {
                        HrefLabel(href: "https://github.com/apple/swift-collections", text: "@apple/swift-collections")
                        HrefLabel(href: "https://github.com/layoutBox/PinLayout", text: "@layoutBox/PinLayout")
                        HrefLabel(href: "https://github.com/hyperoslo/Lightbox", text: "@hyperoslo/Lightbox")
                        HrefLabel(href: "https://github.com/pikachu987/WebController", text: "@pikachu987/WebController")
                        HrefLabel(href: "https://github.com/fjcaetano/ReCaptcha", text: "@fjcaetano/ReCaptcha")
                    }
                } header: {
                    Text("开源代码")
                } footer: {
                    Text("本项目直接或间接地使用或参考了以上开源仓库，感谢所有提供开源代码的开发者。排名不分先后。")
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("致谢")
        }
        .navigationViewStyle(.stack)
    }
}

struct AcknowledgementView_Previews: PreviewProvider {
    static var previews: some View {
        AcknowledgementView()
    }
}
