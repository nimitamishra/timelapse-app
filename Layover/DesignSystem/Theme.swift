import SwiftUI

// The single source of truth for how Layover looks.
// Screens never hard-code a color or font — they ask Theme for one.
// Change a value here and every screen updates.
//
// `enum` with no cases is a Swift trick for a namespace: it groups
// constants and can't be accidentally created (`Theme()` won't compile).
enum Theme {

    // MARK: Colors — the night-cockpit palette from the mockups
    enum Colors {
        static let background    = Color(hex: 0x0B1220) // app background, near-black navy
        static let surface       = Color(hex: 0x141D2E) // cards and panels
        static let surfaceRaised = Color(hex: 0x1A2438) // highlighted row (selected flight)
        static let border        = Color(hex: 0x24304A) // thin panel outlines
        static let borderStrong  = Color(hex: 0x3A4A68) // outlined buttons
        static let textPrimary   = Color(hex: 0xE6EDF7) // main text
        static let textSecondary = Color(hex: 0x8E9BB0) // labels, captions
        static let amber         = Color(hex: 0xFFB547) // accent: route, primary buttons
        static let green         = Color(hex: 0x6EE7A8) // good news: boarding, tailwind
        static let recording     = Color(hex: 0xFF6B5E) // the REC dot

        // The boarding pass is a light paper ticket on the dark screen.
        static let ticketPaper       = Color(hex: 0xE6EDF7)
        static let ticketInk         = Color(hex: 0x0B1220)
        static let ticketInkMuted    = Color(hex: 0x4A5568)
        static let ticketPerforation = Color(hex: 0x9AA6B8)
    }

    // MARK: Fonts — SF Pro for text, SF Mono for flight data
    // Text styles like `.body` and `.caption` grow when someone turns up
    // text size in iOS Settings (Dynamic Type). Fixed sizes don't, so we
    // only use them for big decorative numbers and the split-flap letters.
    enum Fonts {
        static let title   = Font.system(.title2, weight: .bold)
        static let body    = Font.body
        static let label   = Font.caption.weight(.semibold)
        static let readout = Font.system(.headline, design: .monospaced, weight: .bold)
        static let code    = Font.system(.title3, design: .monospaced, weight: .bold) // "BOG", "SFO"
        static let timer   = Font.system(size: 52, weight: .bold, design: .monospaced)
        static let flap    = Font.system(size: 28, weight: .bold, design: .monospaced)
    }

    // MARK: Spacing & shape — a small fixed scale keeps layouts consistent
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat  = 8
        static let m: CGFloat  = 16
        static let l: CGFloat  = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat   = 14
        static let button: CGFloat = 14
        static let flap: CGFloat   = 6
    }
}

// MARK: - Helpers

extension Color {
    /// Lets us write colors the way designers do: `Color(hex: 0xFFB547)`.
    /// Each pair of hex digits is red, green, blue (0–255); we shift and
    /// mask to pull each pair out, then divide by 255 to get 0.0–1.0.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255
        )
    }
}

extension View {
    /// The small uppercase grey label used above values ("ALT", "TASK").
    /// A custom modifier bundles several modifiers under one name.
    func cockpitLabel() -> some View {
        self
            .font(Theme.Fonts.label)
            .textCase(.uppercase)
            .tracking(0.8)
            .foregroundStyle(Theme.Colors.textSecondary)
    }
}
