//
//  ChatExperimentView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/25/24.
//

import SwiftUI
import MarkdownUI

struct ChatExperimentView: View {
    @State var sliderValue: Double = 400.0

    var body: some View {
        Markdown {
            Paragraph {
                "Text"
                InlineImage(source: URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/86/static/light/1.0")!)
                "This is more text"
                "This is text continuing on for a long time, accompanied by"
                InlineImage(source: URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/86/static/light/1.0")!)
                "another inline image. This text keeps going and going and going and going and going"
                InlineImage(source: URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/86/static/light/1.0")!)
                "until another image occurs."
            }
        }
        .frame(width: self.sliderValue)
        .markdownImageProvider(.normalWebImage)
        .markdownInlineImageProvider(.webImage)

        Slider(value: self.$sliderValue, in: 0.0...400.0)

    }
}

struct NormalWebImageProvider: ImageProvider {
    func makeImage(url: URL?) -> some View {
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

#Preview {
    ChatExperimentView()
}
