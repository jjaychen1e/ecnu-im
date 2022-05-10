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
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(viewModel.post.authorName)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                    Text("发布于 \(viewModel.post.createdDateDescription)")
                        .font(.system(size: 14, weight: .light, design: .rounded))
                }
                HStack {
                    if viewModel.post.author?.attributes.isOnline == true {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(rgba: "#7FBA00"))
                                .frame(width: 8, height: 8)
                            Text("在线")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.primary.opacity(0.7))
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
