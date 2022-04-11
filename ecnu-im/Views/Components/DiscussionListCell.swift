//
//  DiscussionListCell.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/3/27.
//

import Introspect
import Kingfisher
import SwiftSoup
import SwiftUI
import UIColorHexSwift

struct DiscussionListCellPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Circle()
                    .fill(Color(rgba: "#D6D6D6"))
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("那只敏捷的棕毛狐狸跳过那只懒狗，消失得无影无踪。")
                        .font(.system(size: 17, weight: .bold))
                    HStack(alignment: .center, spacing: 2) {
                        Text("jjaychen")
                            .font(.system(size: 15, weight: .medium))
                        Text("1 分钟前")
                            .font(.system(size: 12, weight: .light))
                            .frame(alignment: .leading)
                    }
                }
                Spacer()
            }
            Text(String(repeating: " ", count: Int.random(in: 40 ..< 80)))
            Text(String(repeating: " ", count: Int.random(in: 40 ..< 80)))
            Text(String(repeating: " ", count: Int.random(in: 40 ..< 80)))
        }
        .padding(.horizontal, 16)
        .redacted(reason: .placeholder)
    }
}

struct DiscussionListCell: View {
    @Environment(\.splitVC) var splitVC
    @State var discussion: Discussion
    @State var index: Int

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Button {
                    if AppGlobalState.shared.tokenPrepared {
                        let near = (discussion.attributes?.commentCount ?? 1) - 1
                        splitVC?.setSplitViewRoot(viewController: DiscussionViewController(discussion: discussion, near: near),
                                                  column: .secondary,
                                                  immediatelyShow: true)
                    } else {
                        splitVC?.presentSignView()
                    }
                } label: {
                    LastPostCell(discussion: discussion)
                        .background(Color.white.opacity(0.001))
                }
                .buttonStyle(.plain)
            }

            if discussion.firstPost != nil
                && discussion.lastPost != nil
                && discussion.firstPost != discussion.lastPost {
                Button {
                    if AppGlobalState.shared.tokenPrepared {
                        splitVC?.setSplitViewRoot(viewController: DiscussionViewController(discussion: discussion, near: 0),
                                                  column: .secondary,
                                                  immediatelyShow: true)
                    } else {
                        splitVC?.presentSignView()
                    }
                } label: {
                    FirstPostCell(discussion: discussion)
                        .background(Color.white.opacity(0.001))
                }
                .buttonStyle(.plain)
            }

            if discussion.firstPost == nil {
                Text("原帖第一楼被删除，此处应有提醒。")
            }
        }
        .padding(.vertical, 4)
        .onLoad {
            if let splitVC = splitVC {
                if splitVC.traitCollection.horizontalSizeClass != .compact {
                    if index == 0 {
                        splitVC.setSplitViewRoot(viewController: DiscussionViewController(discussion: discussion, near: 0),
                                                 column: .secondary,
                                                 immediatelyShow: true)
                    }
                }
            }
        }
    }
}

private struct FirstPostCell: View {
    @State private var discussion: Discussion
    @State private var dateDescription: String

    init(discussion: Discussion) {
        self.discussion = discussion
        dateDescription = discussion.firstPostDateDescription
    }

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                PostAuthorAvatarView(name: discussion.starterName,
                                     url: discussion.starterAvatarURL,
                                     size: 30)

                VStack(alignment: .leading) {
                    Text(discussion.discussionTitle)
                        .font(.system(size: 15, weight: .bold))
                    HStack {
                        Text(discussion.starterName)
                            .font(.system(size: 12, weight: .medium))
                        Text(dateDescription)
                            .font(.system(size: 10, weight: .light))
                    }
                }
                Spacer()
                Group {
                    Text(Image(systemName: "message.fill")) + Text("原帖")
                }
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .regular))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(rgba: "#1976d2"))
                )
            }

            parseConvertedHTMLViewComponents(views: discussion.firstPostContentExcerptViews,
                                             configuration: .init(imageOnTapAction: { ImageBrowser.shared.present(imageURLs: $1, selectedImageIndex: $0) },
                                                                  imageGridDisplayMode: .narrow))
        }
        .padding(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                .padding(8)
        )
        .onAppear {
            dateDescription = discussion.firstPostDateDescription
        }
    }
}

private struct LastPostCell: View {
    @State private var discussion: Discussion
    @State private var dateDescription: String

    init(discussion: Discussion) {
        self.discussion = discussion
        dateDescription = discussion.lastPostDateDescription
    }

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                PostAuthorAvatarView(name: discussion.lastPostedUserName,
                                     url: discussion.lastPostedUserAvatarURL,
                                     size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(discussion.discussionTitle)
                        .font(.system(size: 17, weight: .bold))
                    HStack(alignment: .top, spacing: 2) {
                        Text(discussion.lastPostedUserName)
                            .font(.system(size: 15, weight: .medium))
                        HStack(spacing: 2) {
                            Text(dateDescription)
                                .font(.system(size: 12, weight: .light))
                                .fixedSize()
                            Spacer()
                            if let tag = discussion.synthesisedTag {
                                DiscussionCellTagView(tag: tag)
                                    .fixedSize()
                            }
                        }
                    }
                }
            }

            parseConvertedHTMLViewComponents(views: discussion.lastPostContentExcerptViews,
                                             configuration: .init(imageOnTapAction: { ImageBrowser.shared.present(imageURLs: $1, selectedImageIndex: $0) },
                                                                  imageGridDisplayMode: .narrow))
        }
        .padding(.horizontal, 16)
        .onAppear {
            dateDescription = discussion.lastPostDateDescription
        }
    }
}

// TODO: Move to a new file
struct ParsedSingleImageView: View {
    @State var urls: [URL]
    @State var index: Int
    @State var onTapAction: (Int, [URL]) -> Void

    var body: some View {
        KFImage.url(urls[index])
            .placeholder {
                ProgressView()
            }
            .loadDiskFileSynchronously()
            .cancelOnDisappear(true)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: 300)
            .onTapGesture {
                onTapAction(index, urls)
            }
            .contextMenu {
                Button(action: {}) {
                    Text("This is a test")
                    Image(systemName: "paintbrush")
                }
            }
    }
}

struct ParsedGridImageView: View {
    @State var urls: [URL]
    @State var index: Int
    @State var onTapAction: (Int, [URL]) -> Void

    var body: some View {
        KFImage.url(urls[index])
            .placeholder {
                ProgressView()
            }
            .loadDiskFileSynchronously()
            .cancelOnDisappear(true)
            .resizable()
            .scaledToFill()
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .clipped()
            .contentShape(Rectangle()) // Clipped cause tappable area overflow
            .onTapGesture {
                onTapAction(index, urls)
            }
            .contextMenu {
                Button(action: {}) {
                    Text("This is a test")
                    Image(systemName: "paintbrush")
                }
            }
    }
}

// TODO: Move to a new file
struct HTMLParseConfiguration {
    var imageOnTapAction: (Int, [URL]) -> Void

    enum ImageGridDisplayMode {
        case wide
        case narrow
    }

    var imageGridDisplayMode: ImageGridDisplayMode
}

// TODO: Move to a new file
extension View {
    @ViewBuilder
    func parseConvertedHTMLViewComponents(views: [Any], configuration: HTMLParseConfiguration) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Color.clear
                .frame(maxHeight: 1)
            ForEach(0 ..< views.count, id: \.self) { index in
                let view = views[index]
                if let anyView = view as? AnyView {
                    anyView
                }

                if let textView = view as? Text {
                    textView
                        .foregroundColor(ThemeManager.shared.theme.primaryText)
                }

                if let imageURLs = view as? [URL?] {
                    let nonNilImageURLs = imageURLs.compactMap { $0 }
                    if nonNilImageURLs.count == 1 {
                        ParsedSingleImageView(urls: nonNilImageURLs, index: 0, onTapAction: configuration.imageOnTapAction)
                    } else if nonNilImageURLs.count > 1 {
                        // https://stackoverflow.com/a/64252041
                        let gridLayout: [GridItem] = {
                            if configuration.imageGridDisplayMode == .wide || nonNilImageURLs.count > 4 {
                                return Array(repeating: .init(.flexible()), count: 3)
                            } else {
                                return Array(repeating: .init(.flexible()), count: 2)
                            }
                        }()
                        LazyVGrid(columns: gridLayout, alignment: .center, spacing: 10) {
                            ForEach(0 ..< nonNilImageURLs.count, id: \.self) { i in
                                ParsedGridImageView(urls: nonNilImageURLs, index: i, onTapAction: configuration.imageOnTapAction)
                            }
                        }
                    }
                }
            }
        }
    }
}
