//
//  SearchResultUser.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/24.
//

import SwiftUI

struct SearchResultUser: View {
    @Binding var user: FlarumUser
    @State var fetchedUser: FlarumUser?

    var body: some View {
        HStack {
            PostAuthorAvatarView(name: user.attributes.displayName, url: user.avatarURL, size: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text("@" + user.attributes.displayName).font(.system(size: 15, weight: .medium, design: .rounded)) +
                    Text(" (\(user.attributes.username))").font(.system(size: 15, weight: .regular, design: .rounded))

                if user.isOnline {
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
                        Text("\(fetchedUser?.lastSeenAtDateDescription ?? user.lastSeenAtDateDescription)在线")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.primary.opacity(0.7))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.0001))
        .onLoad {
            Task {
                if let id = Int(user.id),
                   let user = try? await flarumProvider.request(.user(id: id)).flarumResponse().data.users.first {
                    self.fetchedUser = user
                }
            }
        }
        .onTapGesture {
            UIApplication.shared.presentOnTop(ProfileCenterViewController(userId: user.id), animated: true)
        }
    }
}
