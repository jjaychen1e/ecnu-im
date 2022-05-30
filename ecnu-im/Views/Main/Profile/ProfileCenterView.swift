//
//  ProfileCenterView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/13.
//

import FontAwesome
import SwiftUI

enum ProfileCategory: String, CaseIterable, Identifiable, Hashable {
    static let key = "ProfileCategory"
    case reply
    case discussion
    case badge

    var id: String { rawValue }
}

class ProfileCenterViewModel: ObservableObject {
    @Published var userId: String
    @Published var user: FlarumUser?
    @Published var posts: [FlarumPost] = []
    @Published var discussions: [FlarumDiscussion] = []
    @Published var userBadges: [FlarumUserBadge] = []
    @Published var selectedCategory = ProfileCategory.reply

    init(userId: String) {
        self.userId = userId
    }

    func refresh() {
        DispatchQueue.main.sync {
            withAnimation {
                self.user = nil
                self.posts = []
                self.discussions = []
                self.userBadges = []
            }
        }
    }
}

private class ProfileCenterViewLoadInfo {
    var task: Task<Void, Never>?
    let limit: Int = 30
    var postLoadingOffset: Int = 0
    var discussionLoadingOffset: Int = 0
    var isLoading = false
}

private struct DiscussionWithMode: Hashable {
    private let mode: ProfileCategory = .discussion
    var discussion: FlarumDiscussion
}

private struct PostWithMode: Hashable {
    private let mode: ProfileCategory = .reply
    var post: FlarumPost
}

private struct BadgeCategoryWithMode: Hashable {
    private let mode: ProfileCategory = .badge
    var badgeCategory: FlarumBadgeCategory
}

struct ProfileCenterView: View {
    @ObservedObject private var viewModel: ProfileCenterViewModel
    @ObservedObject var appGlobalState = AppGlobalState.shared
    @State private var withNavigationBar: Bool
    @State private var userFetchTask: Task<Void, Never>?
    @State private var loadInfo = ProfileCenterViewLoadInfo()
    @State private var sequenceQueue = DispatchQueue(label: "ProfileCenterViewLoadQueue")

    @Environment(\.dismiss) var dismiss

    init(userId: String, withNavigationBar: Bool = true) {
        viewModel = .init(userId: "")
        _withNavigationBar = State(initialValue: withNavigationBar)
        update(userId: userId)
    }

    func update(userId: String) {
        viewModel.userId = userId
        fetch(isRefresh: true)
    }

    func update(selectedCategory: ProfileCategory) {
        viewModel.selectedCategory = selectedCategory
    }

    var mainBody: some View {
        Group {
            if let user = viewModel.user {
                List {
                    ProfileCenterViewHeader(user: user, selectedCategory: $viewModel.selectedCategory)
                        .padding(.bottom, 8)
                        .listRowSeparatorTint(.clear) // `listRowSeparator` will cause other row **randomly** lost separator
                        .buttonStyle(PlainButtonStyle())

                    switch viewModel.selectedCategory {
                    case .reply:
                        let postWithModeList = viewModel.posts.map { PostWithMode(post: $0) }
                        ForEach(Array(zip(postWithModeList.indices, postWithModeList)), id: \.1) { index, postWithMode in
                            let post = postWithMode.post
                            let ignored = appGlobalState.ignoredUserIds.contains(user.id)
                            ProfileCenterPostView(user: user, post: post)
                                .buttonStyle(PlainButtonStyle())
                                .dimmedOverlay(ignored: .constant(ignored), isHidden: .constant(post.isHidden))
                                .onAppear {
                                    checkLoadMore(index)
                                }
                        }
                    case .discussion:
                        let discussionWithModeList = viewModel.discussions.map { DiscussionWithMode(discussion: $0) }
                        ForEach(Array(zip(discussionWithModeList.indices, discussionWithModeList)), id: \.1) { index, discussionWithMode in
                            let discussion = discussionWithMode.discussion
                            let ignored = appGlobalState.ignoredUserIds.contains(user.id)
                            ProfileCenterDiscussionView(user: user, discussion: discussion)
                                .buttonStyle(PlainButtonStyle())
                                .dimmedOverlay(ignored: .constant(ignored), isHidden: .constant(discussion.isHidden))
                                .onAppear {
                                    checkLoadMore(index)
                                }
                        }
                    case .badge:
                        let groupedData = Dictionary(grouping: viewModel.userBadges.filter { $0.relationships?.badge.relationships?.category != nil },
                                                     by: { $0.relationships!.badge.relationships!.category })
                        let categories = Array(groupedData.keys).sorted(by: { $0.id < $1.id })
                        let badgeCategoryWithModeList = categories.map { BadgeCategoryWithMode(badgeCategory: $0) }
                        ForEach(Array(zip(badgeCategoryWithModeList.indices, badgeCategoryWithModeList)), id: \.1) { index, badgeCategoryWithMode in
                            let category = badgeCategoryWithMode.badgeCategory
                            let userBadges = groupedData[category] ?? []
                            if userBadges.count > 0 {
                                ProfileCenterBadgeCategoryView(badgeCategory: category, userBadges: userBadges)
                                    .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    fetch(isRefresh: true)
                }
            }
        }
    }

    var body: some View {
        if withNavigationBar {
            NavigationView {
                if let user = viewModel.user {
                    mainBody
                        .navigationBarHidden(false)
                        .navigationTitle("\(user.attributes.displayName)的个人资料")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    dismiss()
                                } label: {
                                    Text("完成")
                                        .font(.system(size: 17, weight: .medium, design: .rounded))
                                }
                            }
                        }
                }
            }
            .navigationViewStyle(.stack)
        } else {
            mainBody
        }
    }

    private func checkLoadMore(_ i: Int) {
        switch viewModel.selectedCategory {
        case .badge:
            break
        case .discussion:
            if i == viewModel.discussions.count - 10 || i == viewModel.discussions.count - 1 {
                fetch()
            }
        case .reply:
            if i == viewModel.posts.count - 10 || i == viewModel.posts.count - 1 {
                fetch()
            }
        }
    }

    private func fetch(isRefresh: Bool = false) {
        sequenceQueue.async {
            if isRefresh {
                loadInfo.task?.cancel()
                loadInfo.task = nil
                loadInfo.postLoadingOffset = 0
                loadInfo.discussionLoadingOffset = 0
                loadInfo.isLoading = true
                viewModel.refresh()
            } else {
                if loadInfo.isLoading {
                    return
                }
            }

            let loadInfo = self.loadInfo
            if isRefresh {
                loadInfo.task = Task {
                    if let id = Int(viewModel.userId) {
                        if let response = try? await flarumProvider.request(.user(id: id)).flarumResponse() {
                            if let user = response.data.users.first {
                                guard !Task.isCancelled else { return }
                                sequenceQueue.async {
                                    guard !Task.isCancelled else { return }
                                    DispatchQueue.main.sync {
                                        withAnimation {
                                            viewModel.user = user
                                            viewModel.userBadges = response.included.userBadges
                                        }
                                    }
                                }
                                FlarumBadgeStorage.shared.store(userBadges: response.included.userBadges)
                                guard !Task.isCancelled else { return }
                                await fetchUserComment(user: user, offset: loadInfo.postLoadingOffset)
                                guard !Task.isCancelled else { return }
                                await fetchUserDiscussion(user: user, offset: loadInfo.discussionLoadingOffset)
                                sequenceQueue.async {
                                    guard !Task.isCancelled else { return }
                                    loadInfo.postLoadingOffset = loadInfo.limit
                                    loadInfo.discussionLoadingOffset = loadInfo.limit
                                    loadInfo.task = nil
                                    loadInfo.isLoading = false
                                }
                            }
                        }
                    }
                }
            } else {
                switch viewModel.selectedCategory {
                case .badge:
                    break
                case .discussion:
                    if let user = viewModel.user {
                        loadInfo.task = Task {
                            await fetchUserDiscussion(user: user, offset: loadInfo.discussionLoadingOffset)
                            sequenceQueue.async {
                                guard !Task.isCancelled else { return }
                                loadInfo.discussionLoadingOffset += loadInfo.limit
                                loadInfo.task = nil
                                loadInfo.isLoading = false
                            }
                        }
                    }
                case .reply:
                    if let user = viewModel.user {
                        loadInfo.task = Task {
                            await fetchUserComment(user: user, offset: loadInfo.postLoadingOffset)
                            sequenceQueue.async {
                                guard !Task.isCancelled else { return }
                                loadInfo.postLoadingOffset += loadInfo.limit
                                loadInfo.isLoading = false
                            }
                        }
                    }
                }
            }
        }
    }

    private func fetchUserComment(user: FlarumUser, offset: Int) async {
        if let response = try? await flarumProvider.request(.postsByUserAccount(account: user.attributes.username,
                                                                                offset: offset,
                                                                                limit: loadInfo.limit,
                                                                                sort: .newest)).flarumResponse() {
            sequenceQueue.async {
                guard !Task.isCancelled else { return }
                withAnimation {
                    DispatchQueue.main.sync {
                        viewModel.posts.append(contentsOf: response.data.posts)
                    }
                }
            }
        }
    }

    private func fetchUserDiscussion(user: FlarumUser, offset: Int) async {
        if let response = try? await flarumProvider.request(.discussionByUserAccount(account: user.attributes.username,
                                                                                     offset: offset,
                                                                                     limit: loadInfo.limit,
                                                                                     sort: .newest)).flarumResponse() {
            sequenceQueue.async {
                guard !Task.isCancelled else { return }
                withAnimation {
                    DispatchQueue.main.sync {
                        viewModel.discussions.append(contentsOf: response.data.discussions)
                    }
                }
            }
        }
    }
}

private struct ProfileCenterViewHeader: View {
    @State var user: FlarumUser
    @Binding var selectedCategory: ProfileCategory

    @ObservedObject var appGlobalState = AppGlobalState.shared

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    HStack(spacing: 2) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.blue)
                        Text("\(user.discussionCount)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.primary.opacity(0.7))
                    }

                    HStack(spacing: 2) {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.teal)
                        Text("\(user.commentCount)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.primary.opacity(0.7))
                    }

                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.pink)
                        Text("\(user.likesReceived)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.primary.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                VStack(spacing: 4) {
                    PostAuthorAvatarView(name: user.attributes.displayName, url: user.avatarURL, size: 80)
                    Text(user.attributes.displayName)
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                }
            }

            VStack(spacing: 8) {
                if let profileAnswers = user.relationships?.profileAnswers {
                    HStack(spacing: 4) {
                        ForEach(Array(zip(profileAnswers.indices, profileAnswers)), id: \.1) { index, profileAnswer in
                            if let (icon, faStyle) = FontAwesome.parseFromFlarum(str: profileAnswer.attributes.field.icon ?? "") {
                                Text(fa: icon, faStyle: faStyle, size: 13)
                                Text("\(profileAnswer.attributes.field.name): \(profileAnswer.attributes.content)")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary.opacity(0.9))
                            }
                        }
                    }
                }

                if appGlobalState.ignoredUserIds.contains(user.id) {
                    Text("已屏蔽")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.red)
                }

                HStack {
                    if user.isOnline {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 12, height: 12)
                            Text("在线")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.primary.opacity(0.7))
                        }
                    } else {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.gray)
                                .frame(width: 12, height: 12)
                            Text("\(user.lastSeenAtDateDescription)在线")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.primary.opacity(0.7))
                        }
                    }

                    HStack(spacing: 4) {
                        Text("注册于\(user.joinDateDescription)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.primary.opacity(0.7))
                    }
                }

                let bio = user.attributes.bio ?? "这个人很懒，什么都没留下。"
                Text(bio == "" ? "这个人很懒，什么都没留下。" : bio)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primary.opacity(0.9))
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
            .overlay(
                PopoverMenu {
                    PopoverMenuItem(title: "分享", systemImage: "square.and.arrow.up", action: {})
                        .disabled(true)
                    if user.attributes.canBeIgnored == true {
                        if user.attributes.ignored == true {
                            PopoverMenuItem(title: "取消屏蔽", systemImage: "person.crop.circle.fill.badge.checkmark", titleColor: .primary, iconColor: .primary, action: {
                                let alertController = UIAlertController(title: "注意", message: "你确定要取消屏蔽该用户吗？", preferredStyle: .alert)
                                alertController.addAction(UIAlertAction(title: "确定", style: .destructive, handler: { action in
                                    if let id = Int(user.id) {
                                        Task {
                                            if let response = try? await flarumProvider.request(.ignoreUser(id: id, ignored: true)).flarumResponse() {
                                                if let _ = response.data.users.first {
                                                    user.attributes.ignored = false
                                                    AppGlobalState.shared.ignoredUserIds.remove(user.id)
                                                    let toast = Toast.default(
                                                        icon: .emoji("🤝🏻"),
                                                        title: "取消屏蔽用户\(user.attributes.displayName)成功"
                                                    )
                                                    toast.show()
                                                }
                                            }
                                        }
                                    }
                                }))
                                alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { action in

                                }))
                                UIApplication.shared.presentOnTop(alertController, animated: true)
                            })
                        } else {
                            PopoverMenuItem(title: "屏蔽", systemImage: "person.crop.circle.fill.badge.minus", titleColor: .red, iconColor: .red, action: {
                                let alertController = UIAlertController(title: "注意", message: "你确定要屏蔽该用户吗？", preferredStyle: .alert)
                                alertController.addAction(UIAlertAction(title: "确定", style: .destructive, handler: { action in
                                    if let id = Int(user.id) {
                                        Task {
                                            if let response = try? await flarumProvider.request(.ignoreUser(id: id, ignored: true)).flarumResponse() {
                                                if let _ = response.data.users.first {
                                                    user.attributes.ignored = true
                                                    AppGlobalState.shared.ignoredUserIds.insert(user.id)
                                                    let toast = Toast.default(
                                                        icon: .emoji("👋🏻"),
                                                        title: "屏蔽用户\(user.attributes.displayName)成功"
                                                    )
                                                    toast.show()
                                                }
                                            }
                                        }
                                    }
                                }))
                                alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { action in

                                }))
                                UIApplication.shared.presentOnTop(alertController, animated: true)
                            })
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .regular, design: .rounded))
                },
                alignment: .bottomTrailing
            )

            Picker("分类", selection: $selectedCategory) {
                Text("回复")
                    .tag(ProfileCategory.reply)
                Text("主题")
                    .tag(ProfileCategory.discussion)
                Text("徽章")
                    .tag(ProfileCategory.badge)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .frame(maxWidth: .infinity)
    }
}
