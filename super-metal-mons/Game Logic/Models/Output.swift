// ∅ 2024 super-metal-mons

import Foundation

enum Output: Codable {
    case invalidInput
    case locationsToStartFrom([Location])
    case nextInputOptions([NextInput])
    case events([Event])

    static func ==(lhs: Output, rhs: Output) -> Bool {
        switch (lhs, rhs) {
        case (.invalidInput, .invalidInput):
            return true
        case let (.locationsToStartFrom(a), .locationsToStartFrom(b)):
            return Set(a) == Set(b)
        case let (.nextInputOptions(a), .nextInputOptions(b)):
            return Set(a) == Set(b)
        case let (.events(a), .events(b)):
            return Set(a) == Set(b)
        default:
            return false
        }
    }
}
