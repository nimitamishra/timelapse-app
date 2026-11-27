import Foundation

/// Turns seconds into the two styles of time text the app shows.
nonisolated enum FlightTimeFormat {
    /// Friendly: "25m", "1h", "1h 30m". Used on chips and labels.
    static func short(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int((seconds / 60).rounded())
        let h = totalMinutes / 60, m = totalMinutes % 60
        switch (h, m) {
        case (0, _): return "\(m)m"
        case (_, 0): return "\(h)h"
        default:     return "\(h)h \(m)m"
        }
    }

    /// Departure-board style: "0:46", "2:05". Hours, then two-digit minutes.
    static func clock(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int((seconds / 60).rounded())
        return String(format: "%d:%02d", totalMinutes / 60, totalMinutes % 60)
    }
}
