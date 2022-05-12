//
//  AllDiscussionsView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/25.
//

import Combine
import RxSwift
import SwiftUI
import SwiftUIPullToRefresh
import SwiftyJSON

struct AllDiscussionsViewNavigationHeader: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Spacer()
                Text("最新话题")
                    .font(.system(size: 19, weight: .bold))
                Spacer()
            }
            .padding()
            Rectangle()
                .foregroundColor(.primary.opacity(0.2))
                .frame(height: 0.5)
        }
        .background(Color(uiColor: .secondarySystemBackground))
    }
}

struct AllDiscussionsView: View {
    private let pageItemLimit = 20
    @State private var discussionList: [FlarumDiscussion] = []
    @State private var pageOffset = 0
    @State private var isLoading = false
    @State private var isLogged = false

    @State private var initialLoadMoreTask: Task<Void, Never>?
    @State private var subscriptions: Set<AnyCancellable> = []

    var body: some View {
        RefreshableScrollView(loadingViewBackgroundColor: ThemeManager.shared.theme.backgroundColor1,
                              action: {
                                  await loadMore(isRefresh: true)
                              }, progress: { state in
                                  RefreshActivityIndicator(isAnimating: state == .loading) {
                                      $0.hidesWhenStopped = false
                                  }
                                  .opacity(state == .waiting ? 0 : 1)
                                  .animation(.default, value: state)
                              }) {
            LazyVStack {
                if discussionList.count > 0 {
                    ForEach(Array(zip(discussionList.indices, discussionList)), id: \.1) { index, discussion in
                        DiscussionListCell(discussion: discussion, index: index)
                            .padding(.bottom, 2)
                            .overlay(
                                Rectangle()
                                    .foregroundColor(.primary.opacity(0.2))
                                    .frame(height: 0.5),
                                alignment: .bottom
                            )
                            .onAppear {
                                checkLoadMore(index)
                            }
                    }
                } else {
                    ForEach(0 ..< 10) { _ in
                        DiscussionListCellPlaceholder()
                            .padding(.bottom, 2)
                            .overlay(
                                Rectangle()
                                    .foregroundColor(.primary.opacity(0.2))
                                    .frame(height: 0.5),
                                alignment: .bottom
                            )
                    }
                }
            }
        }
        .background(ThemeManager.shared.theme.backgroundColor1)
        .onLoad {
            // We cannot just use isLogged, because user may change password
            initialLoadMoreTask = Task {
                await loadMore()
                initialLoadMoreTask = nil
            }

            AppGlobalState.shared.$tokenPrepared.sink { change in
                if let initialLoadMoreTask = initialLoadMoreTask, !initialLoadMoreTask.isCancelled {
                    initialLoadMoreTask.cancel()
                    self.initialLoadMoreTask = nil
                    self.isLoading = false
                }

                Task {
                    await loadMore(isRefresh: true)
                }
            }.store(in: &subscriptions)
        }
    }
}

extension AllDiscussionsView {
    func checkLoadMore(_ i: Int) {
        if i == discussionList.count - 10 || i == discussionList.count - 1 {
            Task {
                await loadMore()
            }
        }
    }

    func loadMore(isRefresh: Bool = false) async {
        guard !isLoading else { return }

        isLoading = true
        if isRefresh {
            pageOffset = 0
        }

        if isRefresh {
            discussionList.removeAll()
        }

        if let response = try? await flarumProvider.request(.allDiscussions(pageOffset: pageOffset, pageItemLimit: pageItemLimit)) {
            let json = JSON(response.data)
            guard !Task.isCancelled else {
                print("cancelled")
                return
            }
            let newDiscussions = FlarumResponse(json: json).data.discussions
            discussionList.append(contentsOf: newDiscussions)
            pageOffset += pageItemLimit
        }
        isLoading = false
    }
}
