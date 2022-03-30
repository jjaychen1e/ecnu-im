//
//  PostAuthorAvatarView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/31.
//

import Foundation
import SwiftUI
import Kingfisher

struct PostAuthorAvatarView: View {
    var name: String
    var url: URL?
    var size: CGFloat

    var body: some View {
        Group {
            if let avatarURL = url {
                KFImage.url(avatarURL)
                    .placeholder {
                        ProgressView()
                    }
                    .loadDiskFileSynchronously()
                    .cancelOnDisappear(true)
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(uiImage: {
                    let avatarView = AvatarView(frame: .init(x: 0, y: 0, width: size, height: size))
                    avatarView.configuration.avatar = .init(image: nil,
                                                            initials: String(name.filter {
                                                                $0 != "@"
                                                            }))
                    return avatarView.image ?? UIImage()
                }())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(Color.gray)
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(size / 2, antialiased: true)
    }
}
