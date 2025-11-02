//
//  ProfileImage.swift
//  Sila
//
//  Created by Adam Gastineau on 11/2/25.
//

import SwiftUI

struct ProfileImage: View {
    let imageUrl: URL?

    var body: some View {
        LoadingAsyncImage(imageUrl: self.imageUrl, aspectRatio: 1.0)
            .clipShape(.rect(cornerRadius: 8))
    }
}
