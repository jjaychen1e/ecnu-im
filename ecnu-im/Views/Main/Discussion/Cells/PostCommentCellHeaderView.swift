//
//  PostCommentCellHeaderView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/10.
//

import SwiftUI

class PostCommentCellHeaderViewModel: ObservableObject {
    @Published var post: FlarumPost

    init(post: FlarumPost) {
        self.post = post
    }

    func update(post: FlarumPost) {
        self.post = post
    }
}

struct PostCommentCellHeaderView: View {
    @EnvironmentObject var uiKitEnvironment: UIKitEnvironment
    @ObservedObject private var viewModel: PostCommentCellHeaderViewModel

    init(post: FlarumPost) {
        viewModel = .init(post: post)
    }

    func update(post: FlarumPost) {
        viewModel.update(post: post)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            PostAuthorAvatarView(name: viewModel.post.authorName, url: viewModel.post.authorAvatarURL, size: 40)
                .onTapGesture {
                    if let id = viewModel.post.author?.id {
                        if let vc = uiKitEnvironment.vc {
                            if vc.presentingViewController != nil {
                                vc.present(ProfileCenterViewController(userId: id),
                                           animated: true)
                            } else {
                                UIApplication.shared.topController()?.present(ProfileCenterViewController(userId: id), animated: true)
                            }
                        } else {
                            #if DEBUG
                                fatalError()
                            #endif
                        }
                    }
                }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(viewModel.post.authorName)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                    Text("发布于 \(viewModel.post.createdDateDescription)")
                        .font(.system(size: 14, weight: .light, design: .rounded))
                    Spacer(minLength: 0)
                    Text("No. \(viewModel.post.attributes?.number ?? -1)")
                        .font(.system(size: 14, weight: .light, design: .rounded))
                }
                HStack {
                    if let author = viewModel.post.author {
                        if author.isOnline {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(rgba: "#7FBA00"))
                                    .frame(width: 8, height: 8)
                                Text("在线")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.primary.opacity(0.7))
                            }
                        } else {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.gray)
                                    .frame(width: 8, height: 8)
                                Text("\(author.lastSeenAtDateDescription)在线")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.primary.opacity(0.7))
                            }
                        }
                    }

                    if let editedDateDescription = viewModel.post.editedDateDescription {
                        Text("重新编辑于 \(editedDateDescription)")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.primary.opacity(0.7))
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
}
