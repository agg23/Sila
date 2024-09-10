import SwiftUI

extension View {
    /// Sets an arbitrary and invisible unicode character as title to reserve space in the navigation bar
    func navigationTitlePlaceholder() -> some View {
        self.navigationTitle("\u{2060}")
    }
}

extension View {
    /// navigationTitle is very small on visionOS 2.0. Insert our own title instead
    func largeNavigationTitle(_ title: String) -> some View {
        self.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text(title)
                    .font(.largeTitle)
            }
        }
    }
}
