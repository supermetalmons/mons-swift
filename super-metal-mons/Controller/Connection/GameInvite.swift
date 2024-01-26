// ∅ 2024 super-metal-mons

import Foundation

struct GameInvite: Codable {
    let version: Int
    let hostId: String
    let hostColor: Color
    let guestId: String?
}
