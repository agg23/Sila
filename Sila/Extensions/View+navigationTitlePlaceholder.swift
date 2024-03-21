import SwiftUI

extension View {
    /// Sets an arbitrary and invisible unicode character as title to reserve space in the navigation bar
    func navigationTitlePlaceholder() -> some View {
        self.navigationTitle("\u{2060}")
    }
}
