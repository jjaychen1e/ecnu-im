//
//  HomeView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/21.
//

import Combine
import SwiftUI
import SwiftyJSON

struct ScrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private class FlarumDiscussionPreviewViewModel: ObservableObject {
    @Published var discussion: FlarumDiscussion
    @Published var postExcerpt: String = ""
    init(discussion: FlarumDiscussion) {
        self.discussion = discussion
    }
}

private class HomeViewViewModel: ObservableObject {
    @Published var stickyDiscussions: [FlarumDiscussionPreviewViewModel] = []
    @Published var newestDiscussions: [FlarumDiscussionPreviewViewModel] = []
}

struct HomeView: View {
    @Environment(\.splitVC) var splitVC
    @ObservedObject private var viewModel = HomeViewViewModel()

    @State private var subscriptions: Set<AnyCancellable> = []
    @State var hasScrolled = false

    private func processDiscussions(discussions: [FlarumDiscussion]) async {
        viewModel.stickyDiscussions = discussions.filter {
            if let attributes = $0.attributes {
                return (attributes.lastReadPostNumber ?? 0 < attributes.lastPostNumber ?? 0) && (attributes.isSticky ?? false || attributes.isStickiest ?? false)
            } else {
                return false
            }
        }.map {
            FlarumDiscussionPreviewViewModel(discussion: $0)
        }

        viewModel.newestDiscussions = discussions.filter {
            !viewModel.stickyDiscussions.map { $0.discussion }.contains($0)
        }.map {
            FlarumDiscussionPreviewViewModel(discussion: $0)
        }

        (viewModel.newestDiscussions + viewModel.stickyDiscussions)
            .compactMap { $0 }
            .forEach {
                $0.postExcerpt = AppGlobalState.shared.tokenPrepared ? "帖子预览内容加载中..." : "登录以查看内容预览"
            }

        let ids = (viewModel.newestDiscussions + viewModel.stickyDiscussions).compactMap { $0.discussion.lastPost?.id }.compactMap { Int($0) }
        if let response = try? await flarumProvider.request(.postsByIds(ids: ids)),
           let json = try? JSON(data: response.data) {
            let posts = FlarumResponse(json: json).data.posts
            for post in posts {
                if let correspondingDiscussionViewModel = (viewModel.newestDiscussions + viewModel.stickyDiscussions).first(where: { $0.discussion.lastPost?.id == post.id }) {
                    if let content = post.attributes?.content,
                       case let .comment(comment) = content {
                        let parser = ContentParser(content: comment,
                                                   configuration: .init(imageOnTapAction: { _, _ in },
                                                                        imageGridDisplayMode: .narrow),
                                                   updateLayout: nil)
                        let postExcerptText = parser.getExcerptContent(configuration:
                            .init(textLengthMax: 100,
                                  textLineMax: 4,
                                  imageCountMax: 0)
                        ).text
                        correspondingDiscussionViewModel.postExcerpt = postExcerptText
                    }
                }
            }
        }
    }

    func load() async {
        if let response = try? await flarumProvider.request(.allDiscussions(pageOffset: 0, pageItemLimit: 20)),
           let json = try? JSON(data: response.data) {
            let newDiscussions = FlarumResponse(json: json).data.discussions
            await processDiscussions(discussions: newDiscussions)
        }
    }

    @State var contentItems: [Any] = []

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

            AppGlobalState.shared.$tokenPrepared.sink { change in
                Task {
                    await load()
                }
            }.store(in: &subscriptions)
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
        if viewModel.stickyDiscussions.count > 0 {
            VStack(alignment: .leading, spacing: 4) {
                Text("置顶")
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .foregroundColor(Asset.SpecialColors.sectionColor.swiftUIColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0 ..< viewModel.stickyDiscussions.count, id: \.self) { index in
                            let viewModel = viewModel.stickyDiscussions[index]
                            Button {
                                if AppGlobalState.shared.tokenPrepared {
                                    let lastReadPostNumber = viewModel.discussion.attributes?.lastReadPostNumber ?? 0
                                    splitVC?.setSplitViewRoot(viewController: DiscussionViewController(discussion: viewModel.discussion, nearNumber: lastReadPostNumber + 1),
                                                              column: .secondary,
                                                              immediatelyShow: true)
                                } else {
                                    splitVC?.presentSignView()
                                }
                            } label: {
                                HomePostCardView(viewModel: viewModel)
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
        if viewModel.newestDiscussions.count > 0 {
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
                        ForEach(0 ..< viewModel.newestDiscussions.count, id: \.self) { index in
                            let viewModel = viewModel.newestDiscussions[index]
                            Button {
                                if AppGlobalState.shared.tokenPrepared {
                                    let lastReadPostNumber = viewModel.discussion.attributes?.lastReadPostNumber ?? 0
                                    splitVC?.setSplitViewRoot(viewController: DiscussionViewController(discussion: viewModel.discussion, nearNumber: lastReadPostNumber + 1),
                                                              column: .secondary,
                                                              immediatelyShow: true)
                                } else {
                                    splitVC?.presentSignView()
                                }
                            } label: {
                                HomePostCardViewLarge(viewModel: viewModel)
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

private struct HomePostCardView: View {
    @ObservedObject private var viewModel: FlarumDiscussionPreviewViewModel

    fileprivate init(viewModel: FlarumDiscussionPreviewViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            VStack(spacing: 4) {
                HStack(alignment: .top) {
                    PostAuthorAvatarView(name: viewModel.discussion.starterName, url: viewModel.discussion.starterAvatarURL, size: 40)
                        .mask(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.discussion.discussionTitle)
                            .lineLimit(1)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Asset.SpecialColors.cardTitleColor.swiftUIColor)
                        HStack(alignment: .top, spacing: 2) {
                            HStack(alignment: .center, spacing: 2) {
                                Text(viewModel.discussion.lastPostedUserName)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                Text(viewModel.discussion.lastPostDateDescription)
                                    .font(.system(size: 10, weight: .regular, design: .rounded))
                                    .fixedSize()
                            }
                            Spacer(minLength: 0)
                            DiscussionTagsView(tags: viewModel.discussion.synthesizedTags)
                                .fixedSize()
//                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                }
                Text(viewModel.postExcerpt)
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
                            Text("\(viewModel.discussion.viewCount)")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                        }
                        HStack(spacing: 1) {
                            Image(systemName: "message")
                                .font(.system(size: 10))
                                .frame(width: 16, height: 16)
                            Text("\(viewModel.discussion.commentCount)")
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
    @ObservedObject private var viewModel: FlarumDiscussionPreviewViewModel

    fileprivate init(viewModel: FlarumDiscussionPreviewViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            VStack(spacing: 4) {
                HStack(alignment: .top) {
                    PostAuthorAvatarView(name: viewModel.discussion.starterName, url: viewModel.discussion.starterAvatarURL, size: 40)
                        .mask(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.discussion.discussionTitle)
                            .lineLimit(1)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Asset.SpecialColors.cardTitleColor.swiftUIColor)
                        HStack(alignment: .top, spacing: 2) {
                            HStack(alignment: .center, spacing: 2) {
                                Text(viewModel.discussion.lastPostedUserName)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                Text(viewModel.discussion.lastPostDateDescription)
                                    .font(.system(size: 10, weight: .regular, design: .rounded))
                            }
                            Spacer(minLength: 0)
                            DiscussionTagsView(tags: viewModel.discussion.synthesizedTags)
                                .fixedSize()
                        }
                    }
                }
                Text(viewModel.postExcerpt)
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
                            Text("\(viewModel.discussion.viewCount)")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                        }
                        HStack(spacing: 1) {
                            Image(systemName: "message")
                                .font(.system(size: 10))
                                .frame(width: 16, height: 16)
                            Text("\(viewModel.discussion.commentCount)")
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
