import SwiftUI
import AppKit

@main
struct PreviewApp: App {
    init() {
        // Overlay scrollers even when the system is set to "always show scroll bars" —
        // legacy scrollers consume layout width and shift panel content.
        UserDefaults.standard.set("WhenScrolling", forKey: "AppleShowScrollBars")
        Theme.registerFonts()
    }

    var body: some Scene {
        WindowGroup("Paper Shaders — Metal Preview") {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
                .background(Theme.surface1)
                .onAppear {
                    // `swift run` launches as a plain process; promote to a regular app
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                    if let iconURL = Bundle.module.url(forResource: "AppIcon", withExtension: "icns") {
                        NSApp.applicationIconImage = NSImage(contentsOf: iconURL)
                    }
                }
        }
    }
}
