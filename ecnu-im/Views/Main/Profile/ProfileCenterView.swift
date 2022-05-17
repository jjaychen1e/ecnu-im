//
//  ProfileCenterView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/13.
//

import SwiftUI

enum ProfileCategory: String, CaseIterable, Identifiable {
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
    @Published var badges: [FlarumBadge] = []
    @Published var selectedCategory = ProfileCategory.reply
    
    init(userId: String) {
        self.userId = userId
    }
}

struct ProfileCenterView: View {
    @ObservedObject private var viewModel: ProfileCenterViewModel
    @State private var userFetchTask: Task<Void, Never>?

    let pageLimit: Int = 20

    init(userId: String) {
        viewModel = .init(userId: userId)
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
                    guard !Task.isCancelled else { return }
                    if let user = response.data.users.first {
                        viewModel.user = user
                        viewModel.badges = response.included.badges
                        viewModel.userBadges = response.included.userBadges
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
            if let user = viewModel.user {
                if let response = try? await flarumProvider.request(.postsByUserAccount(account: user.attributes.username,
                                                                                        offset: offset,
                                                                                        limit: pageLimit,
                                                                                        sort: .newest)).flarumResponse() {
                    viewModel.posts.append(contentsOf: response.data.posts)
                }
            }
        }
    }

    private func fetchUserDiscussion(offset: Int) {
        Task {
            if let user = viewModel.user {
                if let response = try? await flarumProvider.request(.discussionByUserAccount(account: user.attributes.username,
                                                                                             offset: offset,
                                                                                             limit: pageLimit,
                                                                                             sort: .newest)).flarumResponse() {
                    viewModel.discussions.append(contentsOf: response.data.discussions)
                }
            }
        }
    }

    private func fetchUserBadge() {}

    var body: some View {
        Group {
            if let user = viewModel.user {
                List {
                    ProfileCenterViewHeader(user: user, selectedCategory: $viewModel.selectedCategory)
                        .padding(.bottom, 8)
                        .listRowSeparatorTint(.clear) // `listRowSeparator` will cause other row **randomly** lost separator

                    switch viewModel.selectedCategory {
                    case .reply:
                        ForEach(Array(zip(viewModel.posts.indices, viewModel.posts)), id: \.1) { index, post in
                            ProfileCenterPostView(user: user, post: post)
                                .buttonStyle(PlainButtonStyle())
                        }
                    case .discussion:
                        ForEach(Array(zip(viewModel.discussions.indices, viewModel.discussions)), id: \.1) { index, discussion in
                            ProfileCenterDiscussionView(user: user, discussion: discussion)
                                .buttonStyle(PlainButtonStyle())
                        }
                    case .badge:
                        EmptyView()
                        let groupedData = Dictionary(grouping: viewModel.userBadges.filter { $0.relationships?.badge.relationships?.category != nil },
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
    @Binding var selectedCategory: ProfileCategory

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
