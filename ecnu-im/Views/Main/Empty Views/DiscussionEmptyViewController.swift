//
//  DiscussionEmptyViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/12.
//

import SwiftUI
import UIKit

class DiscussionEmptyViewController: UIViewController {
    private var hostingViewController: UIHostingController<EnvironmentWrapperView<DiscussionEmptyView>>!
    weak var splitVC: UISplitViewController?
    weak var nvc: UINavigationController?

    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingViewController = UIHostingController(rootView: EnvironmentWrapperView(
            DiscussionEmptyView(),
            splitVC: splitViewController ?? splitVC,
            nvc: navigationController ?? nvc,
            vc: self
        ))
        self.hostingViewController = hostingViewController
        addChildViewController(hostingViewController, addConstrains: true)
    }
}

/// https://github.com/GetStream/StreamiOSChatSDKPrototyping/blob/main/StreamiOSChatSDKPrototyping/ChannelList/ChannelListEmptyView.swift
struct DiscussionEmptyView: View {
    // 1. Animate From: Chaticon animations
    @State private var blinkLeftEye = true
    @State private var blinkRightEye = true
    @State private var trimMouth = false
    @State private var shake = false

    // 1. Animate From: Writing animation
    @State private var writing = false
    @State private var movingCursor = false
    @State private var blinkingCursor = false

    let cursorColor = Color(#colorLiteral(red: 0, green: 0.368627451, blue: 1, alpha: 1))
    let emptyChatColor = Color(#colorLiteral(red: 0.2997708321, green: 0.3221338987, blue: 0.3609524071, alpha: 1))

    var body: some View {
        VStack {
            ZStack {
                Image("emptyChatDark")
                    .rotationEffect(.degrees(shake ? -5 : 5), anchor: .bottomTrailing)
                VStack {
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 2)
                            .frame(width: 8, height: 4)
                            .scaleEffect(y: blinkRightEye ? 0.1 : 1)
                            .opacity(blinkRightEye ? 0.1 : 1)
                        RoundedRectangle(cornerRadius: 2)
                            .frame(width: 8, height: 4)
                            .scaleEffect(y: blinkLeftEye ? 0.05 : 1)
                    }
                    Circle()
                        .trim(from: trimMouth ? 0.5 : 0.6, to: trimMouth ? 0.9 : 0.8)
                        .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(200))
                }.foregroundColor(emptyChatColor)
                    .rotationEffect(.degrees(shake ? -5 : 5), anchor: .bottomLeading)
            } // 2. Animate To
            .onLoad {
                withAnimation(.easeInOut(duration: 1).repeatForever()) {
                    blinkRightEye.toggle()
                }

                withAnimation(.easeOut(duration: 1).repeatForever()) {
                    blinkLeftEye.toggle()
                }
                withAnimation(.easeOut(duration: 1).repeatForever()) {
                    trimMouth.toggle()
                }

                withAnimation(.easeOut(duration: 1).repeatForever()) {
                    shake.toggle()
                }

                // Writing Animation
                withAnimation(.easeOut(duration: 2).delay(1).repeatForever(autoreverses: true)) {
                    writing.toggle()
                    movingCursor.toggle()
                }

                // Cursor Blinking Animation
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    blinkingCursor.toggle()
                }
            }

            ZStack(alignment: .leading) {
                Text("今天天气如何？")
                    .font(.body)
                    .mask(Rectangle().offset(x: writing ? 0 : -122))
                Rectangle()
                    .fill(cursorColor)
                    .opacity(blinkingCursor ? 0 : 1)
                    .frame(width: 2, height: 24)
                    .offset(x: movingCursor ? 117 : 0)
            }

            Text("从参与一个主题讨论开始来加入我们！")
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }
}
