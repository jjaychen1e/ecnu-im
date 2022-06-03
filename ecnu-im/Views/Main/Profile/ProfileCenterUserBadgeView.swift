//
//  ProfileCenterUserBadgeView.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/17.
//

import FontAwesome
import SwiftUI

struct ProfileCenterBadgeCategoryView: View {
    @State var badgeCategory: FlarumBadgeCategory
    @State var userBadges: [FlarumUserBadge]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(badgeCategory.attributes.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                if let description = badgeCategory.attributes.description {
                    Text(description)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(zip(userBadges.indices, userBadges)), id: \.1) { index, userBadge in
                    ProfileCenterUserBadgeView(userBadge: userBadge)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProfileCenterUserBadgeView: View {
    @State var userBadge: FlarumUserBadge

    var body: some View {
        if let badge = userBadge.relationships?.badge {
            HStack {
                HStack {
                    if let (fa, faStyle) = FontAwesome.parseFromFlarum(str: badge.attributes.icon),
                       let color = Color(rgba: badge.attributes.iconColor) {
                        Image(fa: fa, faStyle: faStyle, color: color)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    }
                    Text(badge.attributes.name)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Color(rgba: badge.attributes.labelColor))
                        .fixedSize()
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color(rgba: badge.attributes.backgroundColor))
                .cornerRadius(4)

                Text(badge.description)
                    .font(.system(size: 15, weight: .medium, design: .rounded))

                Spacer(minLength: 0)

                Group {
                    (Text("于 ") +
                        Text(userBadge.assignedAtDateDescription)
                        .font(.system(size: 15, weight: .medium, design: .rounded)) +
                        Text(" 获得")
                     )
                    .multilineTextAlignment(.trailing)
                }
                .font(.system(size: 15, weight: .light, design: .rounded))
            }
        }
    }
}
