//
//  LanguageFilterView.swift
//  Sila
//
//  Created by Adam Gastineau on 3/17/24.
//

import SwiftUI

private let languageFilterPickerOptionIDs = SUPPORTED_LANGUAGE_IDS.filter { !$0.starts(with: "DIV") }

struct LanguageFilterPickerView: View {
    let title: String
    let language: Binding<String>

    init(language: Binding<String>, title: String = "Language") {
        self.title = title
        self.language = language
    }

    var body: some View {
        Picker(self.title, selection: self.language) {
            ForEach(languageFilterPickerOptionIDs, id: \.self) { id in
                Text(SUPPORTED_LANGUAGES[id] ?? id)
                    .tag(id)
            }
        }
        #if os(tvOS)
        .pickerStyle(.menu)
        #endif
    }
}

#Preview {
    LanguageFilterPickerView(language: .constant("en"))
}
