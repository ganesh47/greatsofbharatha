import SwiftUI

enum GBEmphasis: CaseIterable {
    case story
    case place
    case chronicle
    case neutral
}
enum GBColor {
    enum Background {
        static let app = Color(uiColor: .systemGroupedBackground)
        static let surface = Color(uiColor: .secondarySystemGroupedBackground)
        static let elevated = Color(uiColor: .tertiarySystemBackground)
        static let heroWarmStart = Color(red: 0.86, green: 0.41, blue: 0.16)
        static let heroWarmEnd = Color(red: 0.95, green: 0.73, blue: 0.27)
        static let heroCoolStart = Color(red: 0.20, green: 0.44, blue: 0.70)
        static let heroCoolEnd = Color(red: 0.34, green: 0.64, blue: 0.80)
        static let chronicleStart = Color(red: 0.35, green: 0.28, blue: 0.56)
        static let chronicleEnd = Color(red: 0.62, green: 0.50, blue: 0.25)
    }

    enum Content {
        static let primary = Color.primary
        static let secondary = Color.secondary
        static let tertiary = Color(uiColor: .tertiaryLabel)
        static let inverse = Color.white
    }

    enum Accent {
        static let story = Color.orange
        static let place = Color.blue
        static let chronicle = Color(red: 0.56, green: 0.42, blue: 0.19)
        static let success = Color.green
        static let warning = Color.yellow
    }

    enum Border {
        static let `default` = Color.primary.opacity(0.08)
        static let emphasis = Color.primary.opacity(0.16)
    }

    enum State {
        static let locked = Color.gray
    }

    static func gradient(for emphasis: GBEmphasis) -> LinearGradient {
        switch emphasis {
        case .story:
            LinearGradient(
                colors: [Background.heroWarmStart, Background.heroWarmEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .place:
            LinearGradient(
                colors: [Background.heroCoolStart, Background.heroCoolEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .chronicle:
            LinearGradient(
                colors: [Background.chronicleStart, Background.chronicleEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .neutral:
            LinearGradient(
                colors: [Background.surface, Background.elevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func accent(for emphasis: GBEmphasis) -> Color {
        switch emphasis {
        case .story:
            Accent.story
        case .place:
            Accent.place
        case .chronicle:
            Accent.chronicle
        case .neutral:
            Content.secondary
        }
    }
}
