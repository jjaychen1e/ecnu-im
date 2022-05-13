//
//  TwitterLikeButton.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/12.
//

import SwiftUI

struct TwitterLikeButton: View {
    private static let AnimationPropCircleSize: (CGFloat, CGFloat) = (0.0, 1.3)
    private static let AnimationPropCircleInnerBorder: (Int, Int) = (35, 0)
    private static let AnimationPropCircleHue: (Int, Int) = (200, 300)
    private static let AnimationPropSplash: (CGFloat, CGFloat) = (0.0, 1.5)
    private static let AnimationPropSplashTransparency: (CGFloat, CGFloat) = (1.0, 0.0)
    private static let AnimationPropScaleHeart: (CGFloat, CGFloat) = (0.0, 1.0)
    private static let AnimationPropIconColor: (Color, Color) = (.primary.opacity(0.7), .pink)

    // Animations: Scale, color change and inner stroke (stroke border)
    @State private var circleSize: CGFloat
    @State private var circleInnerBorder: Int
    @State private var circleHue: Int

    // Scale and opacity animations
    @State private var splash: CGFloat
    @State private var splashTransparency: CGFloat

    @State private var scaleHeart: CGFloat

    @State private var iconColor: Color

    @State var action: () -> Void

    @Binding var liked: Bool

    init(action: @escaping () -> Void, liked: Binding<Bool>) {
        self.action = action
        _liked = liked

        if liked.wrappedValue {
            circleSize = Self.AnimationPropCircleSize.1
            circleInnerBorder = Self.AnimationPropCircleInnerBorder.1
            circleHue = Self.AnimationPropCircleHue.1
            splash = Self.AnimationPropSplash.1
            splashTransparency = Self.AnimationPropSplashTransparency.1
            scaleHeart = Self.AnimationPropScaleHeart.1
            iconColor = Self.AnimationPropIconColor.1
        } else {
            circleSize = Self.AnimationPropCircleSize.0
            circleInnerBorder = Self.AnimationPropCircleInnerBorder.0
            circleHue = Self.AnimationPropCircleHue.0
            splash = Self.AnimationPropSplash.0
            splashTransparency = Self.AnimationPropSplashTransparency.0
            scaleHeart = Self.AnimationPropScaleHeart.0
            iconColor = Self.AnimationPropIconColor.0
        }
    }

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                HStack {
                    ZStack {
                        Image(systemName: "heart")
                            .font(.system(size: 20))

                        Circle()
                            .strokeBorder(lineWidth: CGFloat(circleInnerBorder))
                            .animation(Animation.easeInOut(duration: 0.5).delay(0.1), value: circleInnerBorder)
                            .frame(width: 25, height: 25, alignment: .center)
                            .foregroundColor(Color(.systemPink))
                            .hueRotation(Angle(degrees: Double(circleHue)))
                            .scaleEffect(CGFloat(circleSize))
                            .animation(Animation.easeInOut(duration: 0.5), value: circleHue)
                            .animation(Animation.easeInOut(duration: 0.5), value: circleSize)

//                        Image("splash")
//                            .opacity(Double(splashTransparency))
//                            .animation(Animation.easeInOut(duration: 0.5).delay(0.25), value: splashTransparency)
//                            .scaleEffect(CGFloat(splash))
//                            .animation(Animation.easeInOut(duration: 0.5), value: splash)
//
//                        // Rotated splash
//                        Image("splash")
//                            .rotationEffect(.degrees(90))
//                            .opacity(Double(splashTransparency))
//                            .animation(Animation.easeInOut(duration: 0.5).delay(0.2), value: splashTransparency)
//                            .scaleEffect(CGFloat(splash))
//                            .animation(Animation.easeOut(duration: 0.5), value: splash)
                    }
                }

                // Filled heart icon
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .scaleEffect(CGFloat(scaleHeart))
                    .animation(Animation.interpolatingSpring(stiffness: 170, damping: 15).delay(0.25), value: scaleHeart)
            }
            .foregroundColor(iconColor)
        }
        .offset(x: 2.5, y: 2.5)
        .buttonStyle(.plain)
        .onChange(of: liked) { newValue in
            if newValue {
                circleSize = Self.AnimationPropCircleSize.1
                circleInnerBorder = Self.AnimationPropCircleInnerBorder.1
                circleHue = Self.AnimationPropCircleHue.1
                splash = Self.AnimationPropSplash.1
                splashTransparency = Self.AnimationPropSplashTransparency.1
                scaleHeart = Self.AnimationPropScaleHeart.1
                withAnimation(.easeIn) {
                    iconColor = Self.AnimationPropIconColor.1
                }
            } else {
                circleSize = Self.AnimationPropCircleSize.0
                circleInnerBorder = Self.AnimationPropCircleInnerBorder.0
                circleHue = Self.AnimationPropCircleHue.0
                splash = Self.AnimationPropSplash.0
                splashTransparency = Self.AnimationPropSplashTransparency.0
                scaleHeart = Self.AnimationPropScaleHeart.0
                withAnimation(.easeIn) {
                    iconColor = Self.AnimationPropIconColor.0
                }
            }
        }
    }
}
