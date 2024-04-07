//
//  LanguageFilterView.swift
//  Sila
//
//  Created by Adam Gastineau on 3/17/24.
//

import SwiftUI

struct LanguageFilterPickerView: View {
    let title: String
    let language: Binding<String>

    init(language: Binding<String>, title: String = "Language") {
        self.title = title
        self.language = language
    }

    var body: some View {
        Picker(self.title, selection: self.language) {
            // Qualties are saved in reverse order
            ForEach(SUPPORTED_LANGUAGE_IDS, id: \.self) { id in
                if id.starts(with: "DIV") {
                    Divider()
                } else {
                    Button(SUPPORTED_LANGUAGES[id]!) {
                        self.language.wrappedValue = id
                    }
                }
            }
        }
    }
}

#Preview {
    LanguageFilterPickerView(language: .constant("en"))
}
