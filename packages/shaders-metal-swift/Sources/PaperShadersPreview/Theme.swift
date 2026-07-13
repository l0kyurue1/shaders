import SwiftUI
import AppKit
import CoreText

/// Design tokens for the Paper-editor dark look + fluid motion system.
/// Colors sampled from the Paper editor dark theme reference; springs from
/// fluidfunctionalism.com (fast/moderate/slow tiers, tween exits one tier quicker).
enum Theme {


    /// Canvas / preview surround — darkest layer.
    static let surface0 = Color(hex: 0x141414)
    /// Sidebar and panel background.
    static let surface1 = Color(hex: 0x1E1E1E)
    /// Controls: input fields, slider tracks, buttons at rest.
    static let surface2 = Color(hex: 0x2A2A2A)
    /// Hover state of controls.
    static let surface3 = Color(hex: 0x343434)
    /// Popovers / floating menus.
    static let popover = Color(hex: 0x2C2C2C)

    static let textPrimary = Color(hex: 0xF7F6F0)
    static let textSecondary = Color(hex: 0xA4A4A4)
    static let textTertiary = Color(hex: 0x6E6E6E)

    static let accent = Color(hex: 0x5A8CF5)
    static let hairline = Color.white.opacity(0.08)
    static let popoverBorder = Color.white.opacity(0.12)


    static let radius: CGFloat = 8
    static let radiusFocus: CGFloat = 10
    static let radiusPanel: CGFloat = 12


    static func ui(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("InterVariable", size: size).weight(weight)
    }
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Paper Mono", size: size).weight(weight)
    }

    static let label = ui(12)
    static let sectionHeader = ui(11, .medium)
    static let value = mono(11)


    /// fast: chrome (hover, focus, size). moderate: value changes. slow: large surfaces.
    static var fast: Animation { reduced ? reducedAnim : .spring(duration: 0.08, bounce: 0) }
    static var moderate: Animation { reduced ? reducedAnim : .spring(duration: 0.16, bounce: 0) }
    static var slow: Animation { reduced ? reducedAnim : .spring(duration: 0.24, bounce: 0.12) }
    /// Exits are plain tweens, one tier quicker than their enter spring.
    static var fastExit: Animation { reduced ? reducedAnim : .easeOut(duration: 0.06) }
    static var moderateExit: Animation { reduced ? reducedAnim : .easeOut(duration: 0.08) }
    static var slowExit: Animation { reduced ? reducedAnim : .easeOut(duration: 0.16) }

    private static var reduced: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
    private static let reducedAnim: Animation = .linear(duration: 0.01)


    /// Register bundled fonts for this process. Call once before any view renders.
    static func registerFonts() {
        for name in ["InterVariable", "PaperMono"] {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
                ?? Bundle.module.url(forResource: name, withExtension: "ttf") else {
                NSLog("Theme: bundled font %@ not found", name)
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                NSLog("Theme: failed to register %@: %@", name,
                      error?.takeRetainedValue().localizedDescription ?? "unknown")
            }
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
