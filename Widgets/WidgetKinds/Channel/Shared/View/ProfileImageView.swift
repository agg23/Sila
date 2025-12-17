//
//  ProfileImageView.swift
//  WidgetsExtension
//
//  Created by Adam Gastineau on 12/11/25.
//

import SwiftUI
import WidgetKit

struct ProfileImageView: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: self.image)
            .resizable()
            .widgetAccentedRenderingMode(.fullColor)
            .aspectRatio(1.0, contentMode: .fit)
            // Outer widget border radius is 24. MUST BE 12 units from outer edge
            .clipShape(.rect(cornerRadius: 24 - 12))
    }
}
