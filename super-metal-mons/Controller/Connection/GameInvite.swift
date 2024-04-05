// ∅ 2024 super-metal-mons

import Foundation

struct GameInvite: Codable {
    let version: Int
    let hostId: String
    let hostColor: Color
    let guestId: String?
    let password: String?
    
    init(version: Int, hostId: String, hostColor: Color, guestId: String?, password: String? = nil) {
        self.version = version
        self.hostId = hostId
        self.hostColor = hostColor
        self.guestId = guestId
        self.password = password
    }
    
}
