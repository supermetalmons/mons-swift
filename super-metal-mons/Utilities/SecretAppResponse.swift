// ∅ 2024 super-metal-mons

import Foundation

struct SecretAppResponse: Codable {
    
    static func forRequest(_ request: SecretAppRequest, cancel: Bool = false, error: Bool = false) -> [String: String] {
        var dict = [String: String]()
        switch request {
        case .createSecretInvite:
            dict["type"] = "createSecretInvite"
        case let .recoverSecretInvite(id):
            dict["type"] = "recoverSecretInvite"
            dict["id"] = id
        case let .acceptSecretInvite(id, hostId, hostColor, password):
            dict["type"] = "acceptSecretInvite"
            dict["id"] = id
            dict["password"] = password
            dict["hostId"] = hostId
            dict["hostColor"] = hostColor.rawValue
        case let .getSecretGameResult(id, signature, params):
            dict["type"] = "getSecretGameResult"
            dict["id"] = id
            dict["signature"] = signature
            for (key, value) in params {
                dict[key] = value
            }
        }
        
        if cancel {
            dict["cancel"] = "true"
        }
        
        if error {
            dict["error"] = "true"
        }
        
        return dict
    }
    
}
