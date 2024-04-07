//
//  LanguagePickerView.swift
//  Sila
//
//  Created by Adam Gastineau on 4/6/24.
//

import SwiftUI

struct LanguageFilterView<Content: View>: View {
    @AppStorage(Setting.filterLanguage) var filterLanguageSetting: String = "en"

    // Initialize state to the value of the UserDefaults setting
    @State private var selectedLanguage: String = UserDefaults.standard.string(forKey: Setting.filterLanguage) ?? "en"

    let onFilterChange: (_ language: String) async -> Void
    @ViewBuilder var content: (_ language: Binding<String>) -> Content

    var body: some View {
        self.content(self.$selectedLanguage)
            .onChange(of: self.selectedLanguage) { _, newValue in
                // TODO: Should be cancellable
                Task {
                    await self.onFilterChange(newValue)
                }
            }
            .onChange(of: self.filterLanguageSetting, { _, newValue in
                // If setting was changed while this screen was visible, reset value
                self.selectedLanguage = newValue
            })
    }
}
