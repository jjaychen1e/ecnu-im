//
//  HomeView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/21.
//

import SwiftUI
import SwiftyJSON

struct ScrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeView: View {
    @Environment(\.splitVC) var splitVC

    @State var hasScrolled = false

    @State var stickyDiscussions: [FlarumDiscussion] = []
    @State var newestDiscussions: [FlarumDiscussion] = []

    private func processDiscussions(discussions: [FlarumDiscussion]) {
        stickyDiscussions = discussions.filter {
            if let attributes = $0.attributes {
                return (attributes.lastReadPostNumber ?? 0 < attributes.lastPostNumber ?? 0) && (attributes.isSticky ?? false || attributes.isStickiest ?? false)
            } else {
                return false
            }
        }
        newestDiscussions = discussions.filter { !stickyDiscussions.contains($0) }
    }

    func load() async {
        if let response = try? await flarumProvider.request(.allDiscussions(pageOffset: 0, pageItemLimit: 20)),
           let json = try? JSON(data: response.data) {
            let newDiscussions = FlarumResponse(json: json).data.discussions
            processDiscussions(discussions: newDiscussions)
        }
    }

    var body: some View {
        ScrollView {
            Group {
                scrollDetector
                notification
                stickySection()
                latestSection()
            }
            .padding(.bottom)
        }
        .coordinateSpace(name: "scroll")
        .background(
            Image("Background")
                .ignoresSafeArea()
        )
        .background(Asset.SpecialColors.background.swiftUIColor)
        .safeAreaInset(edge: .top) {
            header
        }
        .onLoad {
            Task {
                await load()
            }
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
                    .foregroundColor(.black)
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

    @ViewBuilder
    func stickySection() -> some View {
        if stickyDiscussions.count > 0 {
            VStack(alignment: .leading, spacing: 4) {
                Text("置顶")
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .foregroundColor(Asset.SpecialColors.sectionColor.swiftUIColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(zip(stickyDiscussions.indices, stickyDiscussions)), id: \.1.id) { index, discussion in
                            Button {
                                if AppGlobalState.shared.tokenPrepared {
                                    let near = (discussion.attributes?.lastReadPostNumber ?? 1) - 1
                                    splitVC?.setSplitViewRoot(viewController: DiscussionViewController(discussion: discussion, near: near),
                                                              column: .secondary,
                                                              immediatelyShow: true)
                                } else {
                                    splitVC?.presentSignView()
                                }
                            } label: {
                                HomePostCardView(discussion: discussion)
                                    .overlay(alignment: .topTrailing) {
                                        Image(systemName: "pin.circle.fill")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.white, Color(rgba: "#2864B4"))
                                            .font(.system(size: 30, weight: .regular, design: .rounded))
                                            .rotationEffect(.degrees(45))
                                            .frame(width: 30, height: 30)
                                            .offset(x: 5, y: -5)
                                    }
                            }
                            .buttonStyle(.plain)
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

    @ViewBuilder
    func latestSection() -> some View {
        if newestDiscussions.count > 0 {
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
                .foregroundColor(Asset.SpecialColors.sectionColor.swiftUIColor)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(Array(zip(newestDiscussions.indices, newestDiscussions)), id: \.1.id) { index, discussion in
                            Button {
                                if AppGlobalState.shared.tokenPrepared {
                                    let near = (discussion.attributes?.lastReadPostNumber ?? 1) - 1
                                    splitVC?.setSplitViewRoot(viewController: DiscussionViewController(discussion: discussion, near: near),
                                                              column: .secondary,
                                                              immediatelyShow: true)
                                } else {
                                    splitVC?.presentSignView()
                                }
                            } label: {
                                HomePostCardViewLarge(discussion: discussion)
                            }
                            .buttonStyle(.plain)
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
        } else {
            // TODO: Placeholder
        }
    }
}

struct HomePostCardView: View {
    @State var discussion: FlarumDiscussion

    var body: some View {
        Group {
            VStack(spacing: 4) {
                HStack(alignment: .top) {
                    PostAuthorAvatarView(name: discussion.starterName, url: discussion.starterAvatarURL, size: 40)
                        .mask(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(discussion.discussionTitle)
                            .lineLimit(1)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Asset.SpecialColors.cardTitleColor.swiftUIColor)
                        HStack(alignment: .top, spacing: 2) {
                            HStack(alignment: .center, spacing: 2) {
                                Text(discussion.lastPostedUserName)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                Text(discussion.lastPostDateDescription)
                                    .font(.system(size: 10, weight: .regular, design: .rounded))
                            }
                            DiscussionTagsView(tags: discussion.synthesizedTags)
                                .fixedSize()
                                .frame(maxWidth: .infinity, alignment: .trailing)
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
                            Text("\(discussion.viewCount)")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                        }
                        HStack(spacing: 1) {
                            Image(systemName: "message")
                                .font(.system(size: 10))
                                .frame(width: 16, height: 16)
                            Text("\(discussion.commentCount)")
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
            .background(.ultraThinMaterial)
            .backgroundStyle(cornerRadius: 30, opacity: 0.3)
        }
    }
}

struct HomePostCardViewLarge: View {
    @State var discussion: FlarumDiscussion

    var body: some View {
        Group {
            VStack(spacing: 4) {
                HStack(alignment: .top) {
                    PostAuthorAvatarView(name: discussion.starterName, url: discussion.starterAvatarURL, size: 40)
                        .mask(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(discussion.discussionTitle)
                            .lineLimit(1)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Asset.SpecialColors.cardTitleColor.swiftUIColor)
                        HStack(alignment: .top, spacing: 2) {
                            HStack(alignment: .center, spacing: 2) {
                                Text(discussion.lastPostedUserName)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                Text(discussion.lastPostDateDescription)
                                    .font(.system(size: 10, weight: .regular, design: .rounded))
                            }
                            DiscussionTagsView(tags: discussion.synthesizedTags)
                                .fixedSize()
                                .frame(maxWidth: .infinity, alignment: .trailing)
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
            .background(.ultraThinMaterial)
            .backgroundStyle(cornerRadius: 15, opacity: 0.3)
        }
    }
}
