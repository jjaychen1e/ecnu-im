//
//  SearchView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/23.
//

import Combine
import SwiftUI

class SearchViewModel: ObservableObject {
    @Published var discussions: [FlarumDiscussion] = []
    @Published var users: [FlarumUser] = []
    @Published var searchText = ""
    @Published var selectedSearchCategory: SearchCategory = .posts
}

enum SearchCategory: String, CaseIterable, Identifiable, Hashable {
    case posts
    case users
    var id: String { rawValue }
}

private struct DiscussionWithMode: Hashable {
    private let mode: SearchCategory = .posts
    var discussion: FlarumDiscussion
}

private struct UserWithMode: Hashable {
    private let mode: SearchCategory = .users
    var user: FlarumUser
}

struct SearchView: View {
    @ObservedObject var viewModel = SearchViewModel()
    @State private var subscriptions: Set<AnyCancellable> = []
    @State var task: Task<Void, Never>?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                switch viewModel.selectedSearchCategory {
                case .posts:
                    let discussionWithModeList = viewModel.discussions.map { DiscussionWithMode(discussion: $0) }
                    ForEach(Array(zip(discussionWithModeList.indices, discussionWithModeList)), id: \.1) { index, discussionWithMode in
                        let discussion = discussionWithMode.discussion
                        SearchResultPost(discussion: .constant(discussion))
                    }
                case .users:
                    let userWithModeList = viewModel.users.map { UserWithMode(user: $0) }
                    ForEach(Array(zip(userWithModeList.indices, userWithModeList)), id: \.1) { index, userWithMode in
                        let user = userWithMode.user
                        SearchResultUser(user: .constant(user))
                    }
                }
            }
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Picker("搜索模式", selection: $viewModel.selectedSearchCategory) {
                        Text("帖子")
                            .tag(SearchCategory.posts)
                        Text("用户")
                            .tag(SearchCategory.users)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .fixedSize()
                    .padding(.trailing, 8)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("取消")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .onLoad {
            viewModel.$searchText.debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
                .receive(on: DispatchQueue.main)
                .sink { searchText in
                    if searchText != "" {
                        task?.cancel()
                        task = nil
                        switch viewModel.selectedSearchCategory {
                        case .posts:
                            viewModel.users = []
                            task = Task {
                                if let discussions = try? await flarumProvider.request(.discussionSearch(q: searchText, offset: 0, limit: 20)).flarumResponse().data.discussions {
                                    guard !Task.isCancelled else { return }
                                    viewModel.discussions = discussions
                                }
                            }
                        case .users:
                            viewModel.discussions = []
                            task = Task {
                                if let users = try? await flarumProvider.request(.userSearch(q: searchText, offset: 0, limit: 20)).flarumResponse().data.users {
                                    guard !Task.isCancelled else { return }
                                    viewModel.users = users
                                }
                            }
                        }
                    }
                }
                .store(in: &subscriptions)
        }
    }
}
