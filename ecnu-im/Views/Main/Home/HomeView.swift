//
//  HomeView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/4/21.
//

import Combine
import Regex
import SwiftUI
import SwiftUIPullToRefresh
import SwiftyJSON

struct ScrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private class FlarumDiscussionPreviewViewModel: ObservableObject {
    @Published var discussion: FlarumDiscussion
    @Published var likesUsers: [FlarumUser] = []
    @Published var relatedUsers: [FlarumUser] = []
    @Published var postExcerpt: String = ""
    init(discussion: FlarumDiscussion) {
        self.discussion = discussion
    }
}

private class HomeViewViewModel: ObservableObject {
    @Published var recentOnlineUsers: [FlarumUser] = []
    @Published var recentActiveUsers: [FlarumUser] = []
    @Published var recentRegisteredUsers: [FlarumUser] = []
    @Published var stickyDiscussions: [FlarumDiscussionPreviewViewModel] = []
    @Published var newestDiscussions: [FlarumDiscussionPreviewViewModel] = []
    @Published var unreadNotifications: (unreadCount: Int, notifications: [FlarumNotification])?
    @Published var latestNotificationTitle: String?
    @Published var latestNotificationExcerpt: String?
    @Published var hideNotification = false

    func reset() {
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                self.recentOnlineUsers = []
                self.recentActiveUsers = []
                self.recentRegisteredUsers = []
                self.stickyDiscussions = []
                self.newestDiscussions = []
                self.unreadNotifications = nil
                self.latestNotificationExcerpt = nil
                self.hideNotification = false
            }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var uiKitEnvironment: UIKitEnvironment
    @ObservedObject private var viewModel = HomeViewViewModel()

    @State private var subscriptions: Set<AnyCancellable> = []
    @State private var loadTasks: [Task<Void, Never>] = []

    @State var hasScrolled = false

    @State var isSendingEmail = false

    @ObservedObject var appGlobalState = AppGlobalState.shared

    private func processDiscussions(discussions: [FlarumDiscussion]) async {
        withAnimation {
            viewModel.stickyDiscussions = discussions.filter {
                if let attributes = $0.attributes {
                    return (attributes.lastReadPostNumber ?? 1 < attributes.lastPostNumber ?? 1) && (attributes.isSticky ?? false || attributes.isStickiest ?? false)
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
        }

        let ids = (viewModel.newestDiscussions + viewModel.stickyDiscussions).compactMap { $0.discussion.lastPost?.id }.compactMap { Int($0) }
        if AppGlobalState.shared.tokenPrepared, let response = try? await flarumProvider.request(.postsByIds(ids: ids)).flarumResponse() {
            let posts = response.data.posts
            for post in posts {
                if let correspondingDiscussionViewModel = (viewModel.newestDiscussions + viewModel.stickyDiscussions).first(where: { $0.discussion.lastPost?.id == post.id }) {
                    withAnimation {
                        if let excerpt = post.excerptText(configuration: .init(textLengthMax: 300,
                                                                               textLineMax: 4,
                                                                               imageCountMax: 0)) {
                            correspondingDiscussionViewModel.postExcerpt = excerpt
                        } else {
                            if !AppGlobalState.shared.tokenPrepared {
                                correspondingDiscussionViewModel.postExcerpt = "登录以查看内容预览"
                            } else if AppGlobalState.shared.userInfo?.isEmailConfirmed == false {
                                correspondingDiscussionViewModel.postExcerpt = "无法查看预览内容，请检查账号邮箱是否已验证。"
                            } else {
                                correspondingDiscussionViewModel.postExcerpt = "未知错误，无法查看预览内容"
                            }
                        }
                    }
                }
            }
        }

        for discussion in discussions {
            Task {
                if let correspondingDiscussionViewModel = (viewModel.newestDiscussions + viewModel.stickyDiscussions).first(where: { $0.discussion.id == discussion.id }) {
                    if let users = DiscussionUserStorage.shared.discussionUsers(for: discussion.id),
                       users.count >= 5 || users.count == discussion.attributes?.participantCount {
                        withAnimation {
                            correspondingDiscussionViewModel.relatedUsers = Array(users)
                        }
                    } else {
                        if let id = Int(discussion.id),
                           let response = try? await flarumProvider.request(.posts(discussionID: id, offset: 0, limit: 15)).flarumResponse() {
                            let users = response.data.posts.compactMap { $0.author }
                            let filteredUsers = Array(users.unique { $0.id }.prefix(5))
                            DiscussionUserStorage.shared.store(discussionUsers: filteredUsers, id: discussion.id)
                            withAnimation {
                                correspondingDiscussionViewModel.relatedUsers = filteredUsers
                            }
                        }
                    }
                    Task {
                        if let id = Int(discussion.lastPost?.id ?? ""),
                           let response = try? await flarumProvider.request(.postsById(id: id, includes: [.likes])).flarumResponse() {
                            let users = response.data.posts.first?.relationships?.likes?.unique { $0.id }.prefix(5).compactMap { $0 } ?? []
                            correspondingDiscussionViewModel.likesUsers = Array(users)
                        }
                    }
                }
            }
        }
    }

    func load() {
        for task in loadTasks {
            task.cancel()
        }
        loadTasks = []

        withAnimation {
            viewModel.reset()
        }

        loadTasks.append(
            Task {
                if let response = try? await flarumProvider.request(.allDiscussions(pageOffset: 0, pageItemLimit: 20)).flarumResponse() {
                    guard !Task.isCancelled else { return }

                    let newDiscussions = response.data.discussions
                    await processDiscussions(discussions: newDiscussions)
                }
            }
        )

        loadTasks.append(
            Task {
                if let response = try? await flarumProvider.request(.lastSeenUsers(limit: 20)).flarumResponse() {
                    guard !Task.isCancelled else { return }

                    let users = response.data.users.unique { $0.id }
                    withAnimation {
                        viewModel.recentOnlineUsers = users
                    }
                }
            }
        )

        loadTasks.append(
            Task {
                if let response = try? await flarumProvider.request(.latestPosts(offset: 0, limit: 30)).flarumResponse() {
                    guard !Task.isCancelled else { return }

                    let users = response.data.posts.compactMap { $0.relationships?.user }.unique { $0.id }
                    withAnimation {
                        viewModel.recentActiveUsers = users
                    }
                }
            }
        )

        loadTasks.append(
            Task {
                if let response = try? await flarumProvider.request(.recentRegisteredUsers(limit: 20)).flarumResponse() {
                    guard !Task.isCancelled else { return }

                    let users = response.data.users.unique { $0.id }
                    withAnimation {
                        viewModel.recentRegisteredUsers = users
                    }
                }
            }
        )

        loadTasks.append(
            Task {
                if let response = try? await flarumProvider.request(.home),
                   let string = String(data: response.data, encoding: .utf8) {
                    guard !Task.isCancelled else { return }

                    let regex = Regex("\"unreadNotificationCount\":(\\d+),")
                    if let _str = regex.firstMatch(in: string)?.captures.first,
                       let str = _str,
                       let count = Int(str) {
                        DispatchQueue.main.async {
                            AppGlobalState.shared.unreadNotificationCount = count
                        }
                        if let response = try? await flarumProvider.request(.notification(offset: 0, limit: count + 15)).flarumResponse() {
                            let notifications = response.data.notifications
                                .filter { !$0.attributes.isRead }
                                .sorted { n1, n2 in
                                    if let id1 = Int(n1.id), let id2 = Int(n2.id) {
                                        return id1 > id2
                                    } else {
                                        fatalErrorDebug()
                                        return false
                                    }
                                }
                            if count > 0, notifications.count > 0 {
                                withAnimation {
                                    viewModel.unreadNotifications = (count, notifications)
                                }

                                if let latestNotification = notifications.first {
                                    switch latestNotification.attributes.contentType {
                                    case .postLiked, .postMentioned, .userMentioned, .postReacted, .newPost, .privateDiscussionReplied, .privateDiscussionCreated:
                                        let latestNotificationUserName: String = notifications.first?.relationships?.fromUser?.attributes.displayName ?? "Unkown"
                                        let latestNotificationDiscussionTitle: String = {
                                            if let subject = notifications.first?.relationships?.subject {
                                                switch subject {
                                                case let .post(post):
                                                    return post.relationships?.discussion?.discussionTitle ?? "Unkown"
                                                case let .discussion(discussion):
                                                    return discussion.discussionTitle
                                                case .userBadge:
                                                    break
                                                }
                                            }
                                            return "Unkown"
                                        }()
                                        let latestNotificationTypeDescription = notifications.first?.attributes.contentType.actionDescription ?? "Unkown"
                                        viewModel.latestNotificationTitle = "@\(latestNotificationUserName)\(latestNotificationTypeDescription)了：\(latestNotificationDiscussionTitle)"
                                    case .badgeReceived:
                                        if let subject = notifications[0].relationships?.subject {
                                            if case let .userBadge(userBadgeId) = subject {
                                                if let userBadge = FlarumBadgeStorage.shared.userBadge(for: userBadgeId),
                                                   let badge = userBadge.relationships?.badge {
                                                    withAnimation {
                                                        viewModel.latestNotificationTitle = "你获得了一个新徽章: \(badge.description)！"
                                                    }
                                                } else {
                                                    // We need to fetch from user's api
                                                    Task {
                                                        if let id = AppGlobalState.shared.userIdInt {
                                                            if let response = try? await flarumProvider.request(.user(id: id)).flarumResponse() {
                                                                if appGlobalState.userInfo == nil {
                                                                    DispatchQueue.main.async {
                                                                        appGlobalState.userInfo = response.data.users.first
                                                                    }
                                                                }
                                                                let userBadges = response.included.userBadges
                                                                FlarumBadgeStorage.shared.store(userBadges: userBadges)
                                                                if let userBadge = FlarumBadgeStorage.shared.userBadge(for: userBadgeId),
                                                                   let badge = userBadge.relationships?.badge {
                                                                    withAnimation {
                                                                        viewModel.latestNotificationTitle = "你获得了一个新徽章: \(badge.description)！"
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            } else {
                                                fatalErrorDebug()
                                            }
                                        } else {
                                            fatalErrorDebug()
                                        }
                                    }
                                }

                                switch notifications[0].attributes.contentType {
                                case .postLiked, .postReacted, .privateDiscussionCreated:
                                    if let excerpt = notifications[0].originalPost?.excerptText(configuration: .init(textLengthMax: 150, textLineMax: 3, imageCountMax: 0)) {
                                        withAnimation {
                                            viewModel.latestNotificationExcerpt = excerpt
                                        }
                                    } else {
                                        fatalErrorDebug()
                                    }
                                case .postMentioned, .userMentioned, .newPost, .privateDiscussionReplied:
                                    if let repliedPost = await notifications[0].newPost() {
                                        if let excerpt = repliedPost.excerptText(configuration: .init(textLengthMax: 150, textLineMax: 3, imageCountMax: 0)) {
                                            withAnimation {
                                                viewModel.latestNotificationExcerpt = excerpt
                                            }
                                        }
                                    } else {
                                        fatalErrorDebug()
                                    }
                                case .badgeReceived:
                                    break
                                }
                            }
//                            assertDebug(count == notifications.count)
                        }
                    }
                }
            }
        )
    }

    var body: some View {
        RefreshableScrollView(loadingViewBackgroundColor: .clear,
                              action: {
                                  await load()
                              }, progress: { state in
                                  RefreshActivityIndicator(isAnimating: state == .loading) {
                                      $0.hidesWhenStopped = false
                                  }
                                  .opacity(state == .waiting ? 0 : 1)
                                  .animation(.default, value: state)
                              }) {
            scrollDetector
            LazyVStack {
                emailConfirmNotification()
                notification()
                recentActiveSection()
                recentOnline()
                recentRegisteredSection()
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
            let state = AppGlobalState.shared
            if state.hasTriedToLogin || state.account == nil {
                load()
            }

            state.$tokenPrepared.sink { change in
                if state.hasTriedToLogin {
                    load()
                }
            }.store(in: &subscriptions)

            state.clearNotificationEvent.sink { _ in
                viewModel.hideNotification = true
            }
            .store(in: &subscriptions)
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

    @ViewBuilder
    func emailConfirmNotification() -> some View {
        if appGlobalState.userInfo?.isEmailConfirmed == false, let email = appGlobalState.userInfo?.attributes.email {
            Button {
                EmailVerificationViewController.show()
            } label: {
                HStack {
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(rgba: "#265A9A"))
                    VStack(alignment: .trailing, spacing: 4) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("邮箱尚未验证")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Text("账号激活邮件已发送至\(email)(若未收到请检查垃圾箱)。")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .multilineTextAlignment(.leading)
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        HStack {
                            Text("打开腾讯企业邮箱")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            Spacer(minLength: 0)
                            Button {
                                if let idStr = appGlobalState.userInfo?.id,
                                   let id = Int(idStr) {
                                    Task {
                                        isSendingEmail = true
                                        if let response = try? await flarumProvider.request(.sendEmailConfirmation(userId: id)) {
                                            isSendingEmail = false
                                            if response.statusCode == 204 {
                                                DispatchQueue.main.async {
                                                    let toast = Toast.default(
                                                        icon: .emoji("🎉"),
                                                        title: "重新发送成功"
                                                    )
                                                    toast.show()
                                                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                                                        let alertController = UIAlertController(title: "注意", message: "激活邮件重新发送成功，请登录校园邮箱以激活账号。您想要现在打开腾讯企业邮箱吗？", preferredStyle: .alert)
                                                        alertController.addAction(UIAlertAction(title: "确定", style: .destructive, handler: { action in
                                                            EmailVerificationViewController.show()
                                                        }))
                                                        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { action in
                                                        }))
                                                        UIApplication.shared.presentOnTop(alertController, animated: true)
                                                    }
                                                }
                                            } else {
                                                let toast = Toast.default(
                                                    icon: .emoji("😮"),
                                                    title: "重新发送失败"
                                                )
                                                toast.show()
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Text("重新发送邮件")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .background(
                    Asset.DynamicColors.dynamicWhite.swiftUIColor.opacity(0.7)
                )
                .mask(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal)
            }
            .disabled(isSendingEmail)
            .opacity(isSendingEmail ? 0.5 : 1)
            .overlay(
                Group {
                    if isSendingEmail {
                        ProgressView()
                    }
                },
                alignment: .center
            )
        }
    }

    @ViewBuilder
    func notification() -> some View {
        if !viewModel.hideNotification {
            if let (count, notifications) = viewModel.unreadNotifications {
                let users = notifications
                    .compactMap { $0.relationships?.fromUser }
                    .prefix(5)

                let latestNotificationCreatedDateDescription = notifications.first?.createdDateDescription ?? "Unkown"

                Button {
                    uiKitEnvironment.vc?.tabController?.select(tab: .notifications)
                } label: {
                    HStack {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(Color(rgba: "#265A9A"))
                        VStack(alignment: .leading, spacing: 4) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 2) {
                                    Text("共\(count)条新通知")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    HStack(spacing: -3) {
                                        ForEach(0 ..< users.count, id: \.self) { index in
                                            let user = users[index]
                                            PostAuthorAvatarView(name: user.attributes.displayName, url: user.avatarURL, size: 18)
                                                .mask(Circle())
                                                .overlay(Circle().stroke(Color.white, lineWidth: 0.5))
                                        }
                                    }
                                }
                                HStack {
                                    Text(viewModel.latestNotificationTitle ?? "暂无通知标题")
                                        .lineLimit(1)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    Text(latestNotificationCreatedDateDescription)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .fixedSize(horizontal: true, vertical: true)
                                }
                            }
                            .foregroundColor(Color(rgba: "#045FA1"))
                            if notifications.first?.attributes.contentType != .badgeReceived {
                                Text(viewModel.latestNotificationExcerpt ?? "暂无内容预览")
                                    .animation(nil)
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .lineLimit(3)
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        Spacer(minLength: 0)
                        Button {
                            withAnimation {
                                viewModel.hideNotification = true
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(Color(rgba: "#265A9A"))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                    .background(
                        Color(rgba: "#C8E0F2")
                    )
                    .mask(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(.horizontal)
                }
            }
        }
    }

    var header: some View {
        ZStack {
            Text("ecnu.im")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(Color(rgba: "#A61E35"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                .padding(.top, 20)

            HStack(spacing: 12) {
                Button {
                    UIApplication.shared.presentOnTop(SearchViewController(), animated: true)
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.body.weight(.bold))
                        .frame(width: 36, height: 36)
                        .foregroundColor(.secondary)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .modifier(OutlineOverlay(cornerRadius: 14))
                }

                Button {
                    UIApplication.shared.presentOnTop(NewDiscussionViewController(), animated: true)
                } label: {
                    Image(systemName: "plus.message")
                        .font(.body.weight(.bold))
                        .frame(width: 36, height: 36)
                        .foregroundColor(.secondary)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .modifier(OutlineOverlay(cornerRadius: 14))
                }

                Button {
                    if let _ = appGlobalState.userInfo {
                        uiKitEnvironment.vc?.tabController?.select(tab: .profile)
                    } else {
                        UIApplication.shared.topController()?.presentSignView()
                    }
                } label: {
                    if let user = appGlobalState.userInfo {
                        PostAuthorAvatarView(name: user.attributes.displayName, url: user.avatarURL, size: 28)
                            .frame(width: 28, height: 28)
                            .cornerRadius(10)
                            .padding(4)
                            .background(.ultraThinMaterial)
                            .backgroundStyle(cornerRadius: 18, opacity: 0.4)
                    } else {
                        Image(systemName: "person")
                            .font(.body.weight(.bold))
                            .frame(width: 36, height: 36)
                            .foregroundColor(.secondary)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .modifier(OutlineOverlay(cornerRadius: 14))
                    }
                }
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
    func recentOnline() -> some View {
        if appGlobalState.showRecentOnlineUsers.value, viewModel.recentOnlineUsers.count > 0 {
            VStack(alignment: .leading, spacing: 4) {
                Text("最近在线")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(Asset.SpecialColors.sectionColor.swiftUIColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: -10) {
                        ForEach(0 ..< viewModel.recentOnlineUsers.count, id: \.self) { index in
                            let user = viewModel.recentOnlineUsers[index]
                            PostAuthorAvatarView(name: user.attributes.displayName, url: user.avatarURL, size: 50)
                                .mask(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                .onTapGesture {
                                    UIApplication.shared.presentOnTop(ProfileCenterViewController(userId: user.id), animated: true)
                                }
                                .contentShape(Rectangle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .padding(.vertical, -4)
            }
        }
    }

    @ViewBuilder
    func recentActiveSection() -> some View {
        if appGlobalState.showRecentActiveUsers.value, viewModel.recentActiveUsers.count > 0 {
            VStack(alignment: .leading, spacing: 4) {
                Text("最近活跃")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(Asset.SpecialColors.sectionColor.swiftUIColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: -10) {
                        ForEach(0 ..< viewModel.recentActiveUsers.count, id: \.self) { index in
                            let user = viewModel.recentActiveUsers[index]
                            PostAuthorAvatarView(name: user.attributes.displayName, url: user.avatarURL, size: 50)
                                .mask(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                .onTapGesture {
                                    UIApplication.shared.presentOnTop(ProfileCenterViewController(userId: user.id), animated: true)
                                }
                                .contentShape(Rectangle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .padding(.vertical, -4)
            }
        }
    }

    @ViewBuilder
    func recentRegisteredSection() -> some View {
        if appGlobalState.showRecentRegisteredUsers.value, viewModel.recentRegisteredUsers.count > 0 {
            VStack(alignment: .leading, spacing: 4) {
                Text("最近注册")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(Asset.SpecialColors.sectionColor.swiftUIColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: -10) {
                        ForEach(0 ..< viewModel.recentRegisteredUsers.count, id: \.self) { index in
                            let user = viewModel.recentRegisteredUsers[index]
                            PostAuthorAvatarView(name: user.attributes.displayName, url: user.avatarURL, size: 50)
                                .mask(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                .onTapGesture {
                                    UIApplication.shared.presentOnTop(ProfileCenterViewController(userId: user.id), animated: true)
                                }
                                .contentShape(Rectangle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .padding(.vertical, -4)
            }
        }
    }

    @ViewBuilder
    func stickySection() -> some View {
        if viewModel.stickyDiscussions.count > 0 {
            VStack(alignment: .leading, spacing: 4) {
                Text("置顶")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(Asset.SpecialColors.sectionColor.swiftUIColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0 ..< viewModel.stickyDiscussions.count, id: \.self) { index in
                            let viewModel = viewModel.stickyDiscussions[index]
                            Button {
                                let number = viewModel.discussion.attributes?.lastPostNumber ?? 1
                                uiKitEnvironment.splitVC?.push(viewController: DiscussionViewController(discussion: viewModel.discussion, nearNumber: number),
                                                               column: .secondary,
                                                               toRoot: true)
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
                            .opacity(appGlobalState.ignoredUserIds.contains(viewModel.discussion.starter?.id ?? "") == true ? 0.3 : 1.0)
                        }
                    }
                    .padding(.all, 36)
                }
                .padding(.all, -36)
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
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .padding(.leading)
                    Spacer(minLength: 0)
                    Button {
                        uiKitEnvironment.splitVC?.push(viewController: AllDiscussionsViewController(), column: .primary)
                    } label: {
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
                            let ignored = appGlobalState.ignoredUserIds.contains(viewModel.discussion.starter?.id ?? "")
                            Button {
                                let number = viewModel.discussion.attributes?.lastPostNumber ?? 1
                                uiKitEnvironment.splitVC?.push(viewController: DiscussionViewController(discussion: viewModel.discussion, nearNumber: number),
                                                               column: .secondary,
                                                               toRoot: true)
                            } label: {
                                HomePostCardViewLarge(viewModel: viewModel)
                            }
                            .buttonStyle(.plain)
                            .dimmedOverlay(ignored: .constant(ignored), isHidden: .constant(viewModel.discussion.isHidden))
                        }
                        Button {
                            uiKitEnvironment.splitVC?.push(viewController: AllDiscussionsViewController(), column: .primary)
                        } label: {
                            Text("查看全部")
                                .font(.system(size: 14, weight: .semibold, design: .rounded).bold())
                                .padding(.trailing)
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
    @EnvironmentObject var uiKitEnvironment: UIKitEnvironment

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
                        .overlay(
                            Group {
                                if viewModel.discussion.firstPost?.id != viewModel.discussion.lastPost?.id {
                                    PostAuthorAvatarView(name: viewModel.discussion.lastPostedUserName, url: viewModel.discussion.lastPostedUserAvatarURL, size: 25)
                                        .mask(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                        .overlay(
                                            Color.primary.opacity(0.001)
                                                .offset(x: 10, y: 10)
                                                .onTapGesture {
                                                    if let targetId = viewModel.discussion.lastPostedUser?.id {
                                                        if let account = AppGlobalState.shared.account,
                                                           targetId != account.userIdString {
                                                            UIApplication.shared.presentOnTop(ProfileCenterViewController(userId: targetId), animated: true)
                                                        } else {
                                                            let number = viewModel.discussion.attributes?.lastPostNumber ?? 1
                                                            uiKitEnvironment.splitVC?.push(viewController: DiscussionViewController(discussion: viewModel.discussion, nearNumber: number),
                                                                                           column: .secondary,
                                                                                           toRoot: true)
                                                        }
                                                    }
                                                }
                                        )
                                        .offset(x: 5, y: 0)
                                }
                            },
                            alignment: .bottomTrailing
                        )
                        .onTapGesture {
                            if let account = AppGlobalState.shared.account,
                               let targetId = viewModel.discussion.starter?.id,
                               targetId != account.userIdString {
                                UIApplication.shared.presentOnTop(ProfileCenterViewController(userId: targetId), animated: true)
                            }
                        }
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
                            DiscussionTagsView(tags: .constant(viewModel.discussion.tagViewModels))
                                .fixedSize()
//                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                }
                Text(viewModel.postExcerpt)
                    .animation(nil)
                    .multilineTextAlignment(.leading)
                    .lineLimit(Int.max)
                    .truncationMode(.tail)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                HStack(spacing: 4) {
                    Spacer(minLength: 0)
                    HStack(spacing: -3) {
                        ForEach(0 ..< viewModel.relatedUsers.count, id: \.self) { index in
                            let user = viewModel.relatedUsers[index]
                            PostAuthorAvatarView(name: user.attributes.displayName, url: user.avatarURL, size: 18)
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
            .frame(maxWidth: .infinity, alignment: .topLeading)
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
    @EnvironmentObject var uiKitEnvironment: UIKitEnvironment

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
                        .overlay(
                            Group {
                                if viewModel.discussion.firstPost?.id != viewModel.discussion.lastPost?.id {
                                    PostAuthorAvatarView(name: viewModel.discussion.lastPostedUserName, url: viewModel.discussion.lastPostedUserAvatarURL, size: 25)
                                        .mask(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                        .overlay(
                                            Color.primary.opacity(0.001)
                                                .offset(x: 10, y: 10)
                                                .onTapGesture {
                                                    if let targetId = viewModel.discussion.lastPostedUser?.id {
                                                        if let account = AppGlobalState.shared.account,
                                                           targetId != account.userIdString {
                                                            UIApplication.shared.presentOnTop(ProfileCenterViewController(userId: targetId), animated: true)
                                                        } else {
                                                            let number = viewModel.discussion.attributes?.lastPostNumber ?? 1
                                                            uiKitEnvironment.splitVC?.push(viewController: DiscussionViewController(discussion: viewModel.discussion, nearNumber: number),
                                                                                           column: .secondary,
                                                                                           toRoot: true)
                                                        }
                                                    }
                                                }
                                        )
                                        .offset(x: 5, y: 0)
                                }
                            },
                            alignment: .bottomTrailing
                        )
                        .onTapGesture {
                            if let targetId = viewModel.discussion.starter?.id {
                                if let account = AppGlobalState.shared.account,
                                   targetId != account.userIdString {
                                    UIApplication.shared.presentOnTop(ProfileCenterViewController(userId: targetId), animated: true)
                                } else {
                                    let number = viewModel.discussion.attributes?.lastPostNumber ?? 1
                                    uiKitEnvironment.splitVC?.push(viewController: DiscussionViewController(discussion: viewModel.discussion, nearNumber: number),
                                                                   column: .secondary,
                                                                   toRoot: true)
                                }
                            }
                        }
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
                            DiscussionTagsView(tags: .constant(viewModel.discussion.tagViewModels))
                                .fixedSize()
                        }
                    }
                }
                Text(viewModel.postExcerpt)
                    .animation(nil)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .truncationMode(.tail)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                HStack(spacing: 4) {
                    likeHint
                    Spacer(minLength: 0)
                    HStack(spacing: -3) {
                        ForEach(0 ..< viewModel.relatedUsers.count, id: \.self) { index in
                            let user = viewModel.relatedUsers[index]
                            PostAuthorAvatarView(name: user.attributes.displayName, url: user.avatarURL, size: 18)
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
                .frame(height: 18)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 6)
            .background(.ultraThinMaterial)
            .backgroundStyle(cornerRadius: 15, opacity: 0.3)
        }
    }

    var likeHint: some View {
        Group {
            if let likesUsers = viewModel.likesUsers,
               likesUsers.count > 0 {
                let threshold = 3
                let likesUserName = likesUsers.prefix(threshold).map { $0.attributes.displayName }.joined(separator: ", ")
                    + "\(likesUsers.count > 3 ? "等\(likesUsers.count)人" : "")"
                Group {
                    (Text(Image(systemName: "heart.fill")) + Text(" \(likesUserName)觉得很赞"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.primary.opacity(0.8))
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.primary.opacity(0.8))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(4)
                .onTapGesture {
                    UIApplication.shared.presentOnTop(LikeListViewController(users: likesUsers))
                }
            }
        }
    }
}
