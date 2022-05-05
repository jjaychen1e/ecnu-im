//
//  PostCommentCellHeaderView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/6.
//

import SwiftUI

struct PostCommentCellHeaderView: View {
    @State var user: FlarumUser

    var body: some View {
        HStack(alignment: .top) {
            PostAuthorAvatarView(name: user.attributes.displayName, url: user.avatarURL, size: 40)
                .mask(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 1))
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top, spacing: 2) {
                    HStack(alignment: .center, spacing: 2) {
                        Text("@" + user.attributes.displayName)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        Text("2 天前")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

struct PostCommentCellHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        PostCommentCellHeaderView(user: .init(id: "1", attributes: .init(username: "", displayName: "jjaychen", slug: "")))
            .previewLayout(.sizeThatFits)
    }
}
