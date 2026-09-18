//
//  View+TitleBarToggle.swift
//  Sila
//
//  Created by Adam Gastineau on 7/12/26.
//

import SwiftUI

extension View {
    /// On macOS, automatically hides/shows the window's native title bar
    /// based on whether a video is active. On other platforms, this is a no-op.
    func autoHideTitleBar(isVideoActive: Bool) -> some View {
        #if os(macOS)
        self.background(TitleBarToggleView(isVideoActive: isVideoActive))
        #else
        self
        #endif
    }
}

#if os(macOS)
import AppKit

// MARK: - NSViewRepresentable

private struct TitleBarToggleView: NSViewRepresentable {
    let isVideoActive: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = TitleBarWindowAccessor()
        view.onWindowChange = { window in
            context.coordinator.window = window
            context.coordinator.updateTitleBar(isHidden: self.isVideoActive)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.updateTitleBar(isHidden: isVideoActive)
    }
}

// MARK: - Coordinator

private extension TitleBarToggleView {
    final class Coordinator {
        weak var window: NSWindow?

        func updateTitleBar(isHidden: Bool) {
            guard let window else {
                return
            }

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.allowsImplicitAnimation = true

                window.animator().titlebarAppearsTransparent = isHidden
                window.animator().isMovableByWindowBackground = isHidden
                

                if isHidden {
                    // Ensure full-size content view is set for the transparent
                    // title bar look (content extends behind the title bar area)
                    window.styleMask.insert(.fullSizeContentView)
                }
                // Passing .remove(.fullSizeContentView) causes the sidebar toggle button to move to weird parts of the toolbar
            }
        }
    }
}

// MARK: - Window Accessor View

private final class TitleBarWindowAccessor: NSView {
    var onWindowChange: ((NSWindow?) -> Void)?

    init() {
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        onWindowChange?(window)
    }
}
#endif
