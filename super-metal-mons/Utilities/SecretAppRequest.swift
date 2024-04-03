// ∅ 2024 super-metal-mons

import Foundation

enum SecretAppRequest {
    
    case createSecretInvite
    
    init?(dict: [String: String]) {
        if dict["type"] == "createSecretInvite" {
            self = .createSecretInvite
        } else {
            return nil
        }
    }
    
}
