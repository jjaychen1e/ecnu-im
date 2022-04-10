//
//  HomeView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/21.
//

import SwiftUI

struct ScrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeView: View {
    @State var hasScrolled = false

    var body: some View {
        ScrollView {
            Group {
                scrollDetector
                notification
                stickySection
                latestSection
            }
            .padding(.bottom)
        }
        .coordinateSpace(name: "scroll")
        .background(
            Image("Background")
                .ignoresSafeArea()
        )
        .safeAreaInset(edge: .top) {
            header
        }
    }

    var scrollDetector: some View {
        GeometryReader { proxy in
            Color.clear.preference(key: ScrollPreferenceKey.self, value: proxy.frame(in: .named("scroll")).minY)
        }
        .onPreferenceChange(ScrollPreferenceKey.self) { value in
            withAnimation(.easeInOut(duration: 0.3)) {
                if value < 0 {
                    hasScrolled = true
                } else {
                    hasScrolled = false
                }
            }
        }
        .frame(height: 0)
    }

    var notification: some View {
        HStack {
            Image(systemName: "bell.badge")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(Color(rgba: "#265A9A"))
            VStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 2) {
                        Text("共3条新通知")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        HStack(spacing: -3) {
                            ForEach(0 ..< 5) { _ in
                                Image("avatar")
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                    .mask(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 0.5))
                            }
                        }
                    }
                    HStack {
                        Text("@jjaychen赞了：2018年来华师大的老人回忆上个纪元的生活")
                            .lineLimit(1)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        Text("3小时前")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .fixedSize(horizontal: true, vertical: true)
                    }
                }
                .foregroundColor(Color(rgba: "#045FA1"))
                Text("我敢打包票，这里很多人根本没有经历过真正的大学生活。我时不时会回忆起遥远的过往：没有口罩，没有健康打卡，没有门禁……就像核战后老人在火炉边给孩子们将着还有电力，网络时候的日子那样，我们这些老人娓娓道来……")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .lineLimit(3)
            }
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Color(rgba: "#265A9A"))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            Color(rgba: "#C8E0F2")
        )
        .mask(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal)
    }

    var header: some View {
        ZStack {
            Text("ecnu.im")
                .font(.system(.largeTitle, design: .rounded).bold())
                .foregroundColor(Color(rgba: "#A61E35"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                .padding(.top, 20)

            HStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.body.weight(.bold))
                    .frame(width: 36, height: 36)
                    .foregroundColor(.secondary)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .modifier(OutlineOverlay(cornerRadius: 14))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 20)
            .padding(.top, 20)
        }
        .background(
            Color.clear
                .background(.ultraThinMaterial)
                .blur(radius: 10)
                .opacity(hasScrolled ? 1 : 0)
        )
        .frame(alignment: .top)
    }

    var stickySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("置顶")
                .font(.system(.largeTitle, design: .rounded).bold())
                .foregroundColor(Color(rgba: "#2A5896"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0 ..< 5) { _ in
                        HomePostCardView()
                            .overlay(alignment: .topTrailing) {
                                Image(systemName: "pin.circle.fill")
                                    .font(.system(size: 30, weight: .regular, design: .rounded))
                                    .foregroundColor(Color(rgba: "#2864B4"))
                                    .rotationEffect(.degrees(45))
                                    .frame(width: 30, height: 30)
                                    .offset(x: 5, y: -5)
                            }
                    }
                }
                .padding(.all, 24)
            }
            .padding(.all, -24)
            .safeAreaInset(edge: .leading) {
                Color.clear.frame(width: 8, height: 0)
            }
            .safeAreaInset(edge: .trailing) {
                Color.clear.frame(width: 8, height: 0)
            }
        }
    }

    var latestSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("最新动态")
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .padding(.leading)
                Spacer()
                Button {} label: {
                    Text("查看全部")
                        .font(.system(size: 14, weight: .semibold, design: .rounded).bold())
                        .padding(.trailing)
                }
            }
            .foregroundColor(Color(rgba: "#2A5896"))

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(0 ..< 5) { _ in
                        HomePostCardViewLarge()
                    }
                }
                .padding(.all, 24)
            }
            .padding(.all, -24)
            .safeAreaInset(edge: .leading) {
                Color.clear.frame(width: 8, height: 0)
            }
            .safeAreaInset(edge: .trailing) {
                Color.clear.frame(width: 8, height: 0)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

struct HomePostCardView: View {
    var body: some View {
        Group {
            VStack {
                HStack(alignment: .top) {
                    Image("avatar")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .mask(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    VStack(alignment: .leading) {
                        Text("论坛「排版简易指南」")
                            .lineLimit(1)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(rgba: "#3939A4"))
                        HStack(spacing: 2) {
                            Text("@jjaychen")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                            Text("2周前")
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                            Spacer()
                        }
                    }
                }
                Text("目前帖子内支持的格式有 Markdown 和 BBCode（未来可能会有 HTML 嵌入或 MathJax 数学公式）。另外还会有一些自定义的逻辑，例如图片缩略图和链接预览功能。\n不同专业背景的同学对 Markdown 格式的了解程度不一，又存在一些特殊的排版逻辑...")
                    .multilineTextAlignment(.leading)
                    .lineLimit(Int.max)
                    .truncationMode(.tail)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                
                HStack(spacing: 4) {
                    Spacer()
                    HStack(spacing: -3) {
                        ForEach(0 ..< 3) { _ in
                            Image("avatar")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .mask(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 0.5))
                        }
                    }
                    HStack(spacing: 1) {
                        HStack(spacing: 1) {
                            Image(systemName: "eye")
                                .font(.system(size: 10))
                                .frame(width: 16, height: 16)
                            Text("140")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                        }
                        HStack(spacing: 1) {
                            Image(systemName: "message")
                                .font(.system(size: 10))
                                .frame(width: 16, height: 16)
                            Text("26")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 6)
            .frame(width: 276, height: 165)
            .background(Color.white.opacity(0.4).blur(radius: 5))
            .mask(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .backgroundStyle(cornerRadius: 15, opacity: 0.6)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        }
    }
}

struct HomePostCardViewLarge: View {
    var body: some View {
        Group {
            VStack(spacing: 4) {
                HStack(alignment: .top) {
                    Image("avatar")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .mask(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    VStack(alignment: .leading) {
                        Text("2018 年来华师大的老人回忆上个纪元的生活")
                            .lineLimit(1)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(rgba: "#3939A4"))
                        HStack(spacing: 2) {
                            Text("@bNeutrasterL")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                            Text("2周前")
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                            Spacer()
                        }
                    }
                }
                Text("我敢打包票，这里很多人根本没有经历过真正的大学生活。我时不时会回忆起遥远的过往：没有口罩，没有健康打卡，没有门禁……\n就像核战后老人在火炉边给孩子们将着还有电力，网络时候的日子那样，我们这些老人娓娓道来……")
                    .multilineTextAlignment(.leading)
                    .lineLimit(Int.max)
                    .truncationMode(.tail)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                HStack(spacing: 4) {
                    Spacer()
                    HStack(spacing: -3) {
                        ForEach(0 ..< 3) { _ in
                            Image("avatar")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .mask(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 0.5))
                        }
                    }
                    HStack(spacing: 1) {
                        HStack(spacing: 1) {
                            Image(systemName: "eye")
                                .font(.system(size: 10))
                                .frame(width: 16, height: 16)
                            Text("140")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                        }
                        HStack(spacing: 1) {
                            Image(systemName: "message")
                                .font(.system(size: 10))
                                .frame(width: 16, height: 16)
                            Text("26")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 6)
            .background(Color.white.opacity(0.4).blur(radius: 5))
            .mask(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .backgroundStyle(cornerRadius: 15, opacity: 0.6)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        }
    }
}
