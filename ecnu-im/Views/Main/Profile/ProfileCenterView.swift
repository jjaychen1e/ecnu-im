//
//  ProfileCenterView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/13.
//

import SwiftUI

private enum Category: String, CaseIterable, Identifiable {
    case reply
    case discussion
    case badge

    var id: String { rawValue }
}

struct ProfileCenterView: View {
    @State private var userId: String
    @State private var user: FlarumUser?
    @State private var posts: [FlarumPost] = []
    @State private var discussions: [FlarumDiscussion] = []
    @State private var userBadges: [FlarumUserBadge] = []
    @State private var badges: [FlarumBadge] = []
    @State private var selectedCategory = Category.reply
    @State private var userFetchTask: Task<Void, Never>?

    let pageLimit: Int = 20

    init(userId: String) {
        self.userId = userId
    }

    func update(userId: String) {
        self.userId = userId
        fetchUser()
    }

    private func fetchUser() {
        userFetchTask?.cancel()
        userFetchTask = nil
        userFetchTask = Task {
            if let id = Int(userId) {
                if let response = try? await flarumProvider.request(.user(id: id)).flarumResponse() {
                    guard !Task.isCancelled else { return }
                    if let user = response.data.users.first {
                        self.user = user
                        badges = response.included.badges
                        userBadges = response.included.userBadges
                        FlarumBadgeStorage.shared.store(userBadges: response.included.userBadges)
                        fetchUserComment(offset: 0)
                        fetchUserDiscussion(offset: 0)
                    }
                }
            }
        }
    }

    private func fetchUserComment(offset: Int) {
        Task {
            if let user = user {
                if let response = try? await flarumProvider.request(.postsByUserAccount(account: user.attributes.username,
                                                                                        offset: offset,
                                                                                        limit: pageLimit,
                                                                                        sort: .newest)).flarumResponse() {
                    self.posts.append(contentsOf: response.data.posts)
                }
            }
        }
    }

    private func fetchUserDiscussion(offset: Int) {
        Task {
            if let user = user {
                if let response = try? await flarumProvider.request(.discussionByUserAccount(account: user.attributes.username,
                                                                                             offset: offset,
                                                                                             limit: pageLimit,
                                                                                             sort: .newest)).flarumResponse() {
                    self.discussions.append(contentsOf: response.data.discussions)
                }
            }
        }
    }

    private func fetchUserBadge() {}

    var body: some View {
        Group {
            if let user = user {
                List {
                    ProfileCenterViewHeader(user: user, selectedCategory: $selectedCategory)
                        .padding(.bottom, 8)
                        .listRowSeparatorTint(.clear) // `listRowSeparator` will cause other row **randomly** lost separator

                    switch selectedCategory {
                    case .reply:
                        ForEach(Array(zip(posts.indices, posts)), id: \.1) { index, post in
                            ProfileCenterPostView(user: user, post: post)
                                .buttonStyle(PlainButtonStyle())
                        }
                    case .discussion:
                        ForEach(Array(zip(discussions.indices, discussions)), id: \.1) { index, discussion in
                            ProfileCenterDiscussionView(user: user, discussion: discussion)
                                .buttonStyle(PlainButtonStyle())
                        }
                    case .badge:
                        EmptyView()
                        let groupedData = Dictionary(grouping: userBadges.filter { $0.relationships?.badge.relationships?.category != nil },
                                                     by: { $0.relationships!.badge.relationships!.category })
                        let categories = Array(groupedData.keys).sorted(by: { $0.id < $1.id })
                        ForEach(Array(zip(categories.indices, categories)), id: \.1) { index, category in
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
        .onLoad {
            fetchUser()
        }
    }
}

private struct ProfileCenterViewHeader: View {
    @State var user: FlarumUser
    @Binding var selectedCategory: Category

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
                HStack(spacing: 4) {
                    Text(fa: .school, faStyle: .solid, size: 13)
                    Text("校区: 中北")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.primary.opacity(0.9))
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
            }

            Picker("分类", selection: $selectedCategory) {
                Text("回复")
                    .tag(Category.reply)
                Text("主题")
                    .tag(Category.discussion)
                Text("徽章")
                    .tag(Category.badge)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .frame(maxWidth: .infinity)
    }
}
