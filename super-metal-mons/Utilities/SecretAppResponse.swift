// ∅ 2024 super-metal-mons

import Foundation

struct SecretAppResponse: Codable {
    
    static func forRequest(_ request: SecretAppRequest) -> [String: String] {
        var dict = [String: String]()
        switch request {
        case .createSecretInvite:
            dict["type"] = "createSecretInvite"
        case .recoverSecretInvite(let id):
            dict["type"] = "recoverSecretInvite"
            dict["id"] = id
        case .acceptSecretInvite(let id, let password):
            dict["type"] = "acceptSecretInvite"
            dict["id"] = id
            dict["password"] = "password"
        case .getSecretGameResult(let id, let signature):
            dict["type"] = "getSecretGameResult"
            dict["id"] = id
            dict["signature"] = signature
        }
        return dict
    }
    
}
