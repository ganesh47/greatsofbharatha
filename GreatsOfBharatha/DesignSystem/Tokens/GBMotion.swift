import SwiftUI

enum GBMotion {
    static let quick = Animation.easeOut(duration: 0.18)
    static let standard = Animation.easeInOut(duration: 0.28)
    static let emphasized = Animation.spring(response: 0.38, dampingFraction: 0.82)
}
