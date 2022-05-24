//
//  LikeListView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/24.
//

import SwiftUI

struct LikeListView: View {
    @Environment(\.dismiss) var dismiss
    @State var users: [FlarumUser]

    var body: some View {
        NavigationView {
            List {
                ForEach(users, id: \.self) { user in
                    SearchResultUser(user: .constant(user))
                }
            }
            .navigationTitle("喜欢这篇帖子的人")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("完成")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
