//
//  TextImageView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/2/24.
//

import UIKit
import NukeUI
import Gifu

class ImageView: UIView {
    private let imageView: LazyImageView

    override init(frame: CGRect) {
        self.imageView = LazyImageView(frame: frame)
        self.imageView.makeImageView = { container in
            guard let data = container.data else {
                return nil
            }

            // We create a gif view whether animated gif or not
            let view = GIFImageView(frame: frame)
            view.animate(withGIFData: data)
            return view
        }

        super.init(frame: frame)

        self.addSubview(self.imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImage(with url: URL) {
        self.imageView.url = url
    }

    private func prepareForReuse() {
        self.imageView.reset()
    }
}
