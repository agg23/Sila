//
//  NukeImageProvider.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/1/24.
//

import SwiftUI
import MarkdownUI
import Nuke
import NukeUI

//struct NormalWebImageProvider: ImageProvider {
//    @MainActor
//    func makeImage(url: URL?) -> some View {
//        // TODO: Use caching image fetcher
//        ResizeToFit {
//            AsyncImage(url: url, content: { image in
//                image
//                    .resizable()
//            }) {
//                Rectangle()
//            }
//        }
//        LazyImage(url: url)
//            .frame(width: 28, height: 28)
//    }
//}
//
//extension ImageProvider where Self == NormalWebImageProvider {
//  static var normalWebImage: Self {
//    .init()
//  }
//}
//

//struct WebImageProvider: InlineImageProvider {
//    func image(with url: URL, label: String) async throws -> Image {
////        ResizeToFit {
////            AsyncImage(url: url, content: { image in
////                image
////                    .resizable()
////            }) {
////                Rectangle()
////            }
////        }
////        let (data, _) = try await URLSession.shared.data(from: url)
////        return Image(uiImage: UIImage(data: data)!)
//        LazyImage(url: url)
//            .frame(width: 28, height: 28)
//    }
//}
//
//extension InlineImageProvider where Self == WebImageProvider {
//  static var webImage: Self {
//    .init()
//  }
//}

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
