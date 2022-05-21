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
}

struct ProfileCenterView: View {
    struct DiscussionWithMode: Hashable {
        private let mode: ProfileCategory = .discussion
        var discussion: FlarumDiscussion
    }

    struct PostWithMode: Hashable {
        private let mode: ProfileCategory = .reply
        var post: FlarumPost
    }

    struct BadgeCategoryWithMode: Hashable {
        private let mode: ProfileCategory = .badge
        var badgeCategory: FlarumBadgeCategory
    }

    @ObservedObject private var viewModel: ProfileCenterViewModel
    @ObservedObject var appGlobalState = AppGlobalState.shared
    @State private var userFetchTask: Task<Void, Never>?

    let pageLimit: Int = 20

    init(userId: String) {
        viewModel = .init(userId: "")
        update(userId: userId)
    }

    func update(userId: String) {
        viewModel.userId = userId
        fetchUser()
    }

    func update(selectedCategory: ProfileCategory) {
        viewModel.selectedCategory = selectedCategory
    }

    private func fetchUser() {
        userFetchTask?.cancel()
        userFetchTask = nil
        userFetchTask = Task {
            if let id = Int(viewModel.userId) {
                if let response = try? await flarumProvider.request(.user(id: id)).flarumResponse() {
                    guard !Task.isCancelled else {
                        return
                    }
                    if let user = response.data.users.first {
                        viewModel.user = user
                        viewModel.userBadges = response.included.userBadges
                        FlarumBadgeStorage.shared.store(userBadges: response.included.userBadges)
                        await fetchUserComment(offset: 0)
                        await fetchUserDiscussion(offset: 0)
                    }
                }
            }
        }
    }

    private func fetchUserComment(offset: Int) async {
        if let user = viewModel.user {
            if let response = try? await flarumProvider.request(.postsByUserAccount(account: user.attributes.username,
                                                                                    offset: offset,
                                                                                    limit: pageLimit,
                                                                                    sort: .newest)).flarumResponse() {
                guard !Task.isCancelled else { return }
                viewModel.posts.append(contentsOf: response.data.posts)
            }
        }
    }

    private func fetchUserDiscussion(offset: Int) async {
        if let user = viewModel.user {
            if let response = try? await flarumProvider.request(.discussionByUserAccount(account: user.attributes.username,
                                                                                         offset: offset,
                                                                                         limit: pageLimit,
                                                                                         sort: .newest)).flarumResponse() {
                guard !Task.isCancelled else { return }
                viewModel.discussions.append(contentsOf: response.data.discussions)
            }
        }
    }

    var body: some View {
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
                        }
                    case .discussion:
                        let discussionWithModeList = viewModel.discussions.map { DiscussionWithMode(discussion: $0) }
                        ForEach(Array(zip(discussionWithModeList.indices, discussionWithModeList)), id: \.1) { index, discussionWithMode in
                            let discussion = discussionWithMode.discussion
                            let ignored = appGlobalState.ignoredUserIds.contains(user.id)
                            ProfileCenterDiscussionView(user: user, discussion: discussion)
                                .buttonStyle(PlainButtonStyle())
                                .dimmedOverlay(ignored: .constant(ignored), isHidden: .constant(discussion.isHidden))
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

                Text(user.attributes.bio ?? "这个人很懒，什么都没留下。")
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
                                UIApplication.shared.topController()?.present(alertController, animated: true)
                            })
                        } else if user.attributes.ignored == false {
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
                                UIApplication.shared.topController()?.present(alertController, animated: true)
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
