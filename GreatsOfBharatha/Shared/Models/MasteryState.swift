import Foundation

enum MasteryState: String, CaseIterable, Codable, Equatable, Comparable {
    case witnessed = "Witnessed"
    case understood = "Understood"
    case observedClosely = "Observed Closely"
    case remembered = "Remembered"
    case placed = "Placed"
    case chronicled = "Chronicled"

    var rank: Int {
        switch self {
        case .witnessed:
            return 0
        case .understood:
            return 1
        case .observedClosely:
            return 2
        case .remembered:
            return 3
        case .placed:
            return 4
        case .chronicled:
            return 5
        }
    }

    static func < (lhs: MasteryState, rhs: MasteryState) -> Bool {
        lhs.rank < rhs.rank
    }
}
