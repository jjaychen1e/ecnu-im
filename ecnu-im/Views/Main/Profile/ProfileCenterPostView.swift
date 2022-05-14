//
//  ProfileCenterPostView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/14.
//

import SwiftUI

struct ProfileCenterPostView: View {
    @EnvironmentObject var uiKitEnvironment: UIKitEnvironment

    @State var user: FlarumUser
    @State var post: FlarumPost

    var body: some View {
        let discussionTitle = post.relationships?.discussion?.discussionTitle ?? "Unkown"
        let postExcerptText = post.excerptText(configuration: .init(textLengthMax: 200, textLineMax: 5, imageCountMax: 0)) ?? "无预览内容"

        VStack(alignment: .leading, spacing: 6) {
            Text("\(discussionTitle)")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.init(rgba: "#667A99"))

            HStack(alignment: .top) {
                PostAuthorAvatarView(name: user.attributes.displayName, url: user.avatarURL, size: 40)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(user.attributes.displayName)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                        Text(post.createdDateDescription)
                            .font(.system(size: 14, weight: .light, design: .rounded))
                            .foregroundColor(.primary.opacity(0.7))
                    }

                    HStack {
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
                                Text("\(user.lastSeenAtDateDescription)在线")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.primary.opacity(0.7))
                            }
                        }

                        if let editedDateDescription = post.editedDateDescription {
                            Text("重新编辑于 \(editedDateDescription)")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.primary.opacity(0.7))
                        }
                    }
                }
            }

            Text(postExcerptText)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.primary.opacity(0.7))
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            ProfileCenterPostFooterView(post: post)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.0001))
        .onTapGesture {
            if AppGlobalState.shared.tokenPrepared {
                if let discussion = post.relationships?.discussion,
                   let number = post.attributes?.number {
                    if let vc = uiKitEnvironment.vc {
                        if vc.presentingViewController != nil {
                            vc.present(DiscussionViewController(discussion: discussion, nearNumber: number),
                                       animated: true)
                        } else if let splitVC = uiKitEnvironment.splitVC {
                            splitVC.push(viewController: DiscussionViewController(discussion: discussion, nearNumber: number),
                                         column: .secondary,
                                         toRoot: true)
                        } else {
                            #if DEBUG
                                fatalError()
                            #endif
                        }
                    } else {
                        #if DEBUG
                            fatalError()
                        #endif
                    }
                }
            } else {
                UIApplication.shared.topController()?.presentSignView()
            }
        }
    }
}
