//
//  ChatMessageView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/29/24.
//

import SwiftUI
import TwitchIRC
import MarkdownUI

struct ChatMessageView: View {
    let message: PrivateMessage

    let content: MarkdownContent

    init(message: PrivateMessage) {
        self.message = message
        let emotes = message.parseEmotes()

        var segments: [InlineNode] = []

        let messageString = message.message

        var previousMinIndex = String.Index(utf16Offset: 0, in: messageString)

        for emote in emotes {
            let endIndex = String.Index(utf16Offset: emote.startIndex, in: messageString)

            segments.append(.text(String(messageString[previousMinIndex..<endIndex])))
            segments.append(.image(source: emoteUrl(from: emote.id), children: []))

            previousMinIndex = String.Index(utf16Offset: emote.endIndex, in: messageString)
        }

        // Add final segment
        segments.append(.text(String(messageString[previousMinIndex..<messageString.endIndex])))

        self.content = MarkdownContent(block: .paragraph(content: segments))
    }

    var body: some View {
        Markdown(self.content)
            .markdownImageProvider(.normalWebImage)
            .markdownInlineImageProvider(.webImage)
    }
}

func emoteUrl(from id: String) -> String {
    "https://static-cdn.jtvnw.net/emoticons/v2/\(id)/default/light/1.0"
}

struct NormalWebImageProvider: ImageProvider {
    func makeImage(url: URL?) -> some View {
        // TODO: Use caching image fetcher
        ResizeToFit {
            AsyncImage(url: url, content: { image in
                image
                    .resizable()
            }) {
                Rectangle()
            }
        }
    }
}

extension ImageProvider where Self == NormalWebImageProvider {
  static var normalWebImage: Self {
    .init()
  }
}


struct WebImageProvider: InlineImageProvider {
    func image(with url: URL, label: String) async throws -> Image {
//        ResizeToFit {
//            AsyncImage(url: url, content: { image in
//                image
//                    .resizable()
//            }) {
//                Rectangle()
//            }
//        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return Image(uiImage: UIImage(data: data)!)
    }
}

extension InlineImageProvider where Self == WebImageProvider {
  static var webImage: Self {
    .init()
  }
}

/// A layout that resizes its content to fit the container **only** if the content width is greater than the container width.
struct ResizeToFit: Layout {
  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    guard let view = subviews.first else {
      return .zero
    }

    var size = view.sizeThatFits(.unspecified)

    if let width = proposal.width, size.width > width {
      let aspectRatio = size.width / size.height
      size.width = width
      size.height = width / aspectRatio
    }
    return size
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    guard let view = subviews.first else { return }
    view.place(at: bounds.origin, proposal: .init(bounds.size))
  }
}
