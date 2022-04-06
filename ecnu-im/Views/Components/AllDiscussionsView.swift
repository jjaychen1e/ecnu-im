//
//  AllDiscussionsView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/25.
//

import SwiftUI
import SwiftUIPullToRefresh
import SwiftyJSON

struct AllDiscussionsViewWithTokenCheck: View {
    @ObservedObject var appGlobalState = AppGlobalState.shared

    var body: some View {
        if appGlobalState.tokenPrepared {
            AllDiscussionsView()
        } else {
            ThemeManager.shared.theme.backgroundColor1
                .overlay(Text("Loading..."))
                .edgesIgnoringSafeArea(.all)
        }
    }
}

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
    @State private var discussionList: [Discussion] = []
    @State private var pageOffset = 0
    @State private var isLoading = false

    var body: some View {
        RefreshableScrollView(loadingViewBackgroundColor: ThemeManager.shared.theme.backgroundColor1,
                              action: {
                                  pageOffset = 0
                                  await loadMore(isRefresh: true)
                              }, progress: { state in
                                  RefreshActivityIndicator(isAnimating: state == .loading) {
                                      $0.hidesWhenStopped = false
                                  }
                                  .opacity(state == .waiting ? 0 : 1)
                                  .animation(.default, value: state)
                              }) {
            LazyVStack {
                ForEach(Array(zip(discussionList.indices, discussionList)), id: \.1) { index, discussion in
                    DiscussionListCell(discussion: discussion, index: index)
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
            }
        }
        .background(ThemeManager.shared.theme.backgroundColor1)
        .onLoad {
            Task {
                await loadMore()
            }
        }
    }
}

extension AllDiscussionsView {
    func checkLoadMore(_ i: Int) {
        if !isLoading && (i == discussionList.count - 10 || i == discussionList.count - 1) {
            Task {
                await loadMore()
            }
        }
    }

    func loadMore(isRefresh: Bool = false) async {
        isLoading = true
        if let response = try? await flarumProvider.request(.allDiscussions(pageOffset: pageOffset, pageItemLimit: pageItemLimit)),
           let json = try? JSON(data: response.data) {
            var discussionList: [Discussion] = []

            let includedData = DataParser.parseIncludedData(json: json["included"])
            let includedUsers = includedData.includedUsers
            let includedPosts = includedData.includedPosts
            let includedTags = includedData.includedTags

            if let discussionListJSON = json["data"].array {
                for discussionJSON in discussionListJSON {
                    let relationshipsJSON = discussionJSON["relationships"]
                    let discussionJSONWithoutRelationships = discussionJSON.removing(key: "relationships")
                    if let discussionData = try? discussionJSONWithoutRelationships.rawData(),
                       var discussion = try? JSONDecoder().decode(Discussion.self, from: discussionData) {
                        var relationships = DiscussionRelationship()
                        relationships.user = relationshipsJSON["user"]["data"]["id"].string
                        relationships.lastPostedUser = relationshipsJSON["lastPostedUser"]["data"]["id"].string
                        relationships.firstPost = relationshipsJSON["firstPost"]["data"]["id"].string
                        relationships.lastPost = relationshipsJSON["lastPost"]["data"]["id"].string
                        if let tagsJSON = relationshipsJSON["tags"]["data"].array {
                            relationships.tags = tagsJSON.compactMap { $0["id"].string }
                        }
                        if let recipientUsersJSON = relationshipsJSON["recipientUsers"]["data"].array {
                            relationships.recipientUsers = recipientUsersJSON.compactMap { $0["id"].string }
                        }
                        if let recipientGroups = relationshipsJSON["recipientGroups"]["data"].array {
                            relationships.recipientGroups = recipientGroups.compactMap { $0["id"].string }
                        }

                        var userIds = [
                            relationships.user,
                            relationships.lastPostedUser,
                        ].compactMap { $0 }
                        userIds.append(contentsOf: relationships.recipientUsers ?? [])

                        let postIds = [
                            relationships.firstPost,
                            relationships.lastPost,
                        ].compactMap { $0 }

                        let tagIds = (relationships.tags ?? []).compactMap { $0 }

                        discussion.includedUsers.append(contentsOf: includedUsers.filter { userIds.contains($0.id) })
                        discussion.includedPosts.append(contentsOf: includedPosts.filter { postIds.contains($0.id) })
                        discussion.includedTags.append(contentsOf: includedTags.filter { tagIds.contains($0.id) })
                        discussion.relationships = relationships
                        discussionList.append(discussion)
                    }
                }
            }

            if isRefresh {
                self.discussionList.removeAll()
            }
            self.discussionList.append(contentsOf: discussionList)
            pageOffset += pageItemLimit
        }
        isLoading = false
    }
}
