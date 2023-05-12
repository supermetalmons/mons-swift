// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

struct GameInvite: Codable {
    let version: Int
    let hostId: String
    let hostColor: Color
    let guestId: String?
}
