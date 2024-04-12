// ∅ 2024 super-metal-mons

import Foundation

enum SecretAppRequest {
    
    case createSecretInvite
    case recoverSecretInvite(id: String)
    case acceptSecretInvite(id: String, hostId: String, hostColor: Color, password: String)
    case getSecretGameResult(id: String, signature: String, params: [String: String])
    
    init?(dict: [String: String]) {
        switch dict["type"] {
        case "createSecretInvite":
            self = .createSecretInvite
        case "recoverSecretInvite":
            guard let id = dict["id"] else { return nil }
            self = .recoverSecretInvite(id: id)
        case "acceptSecretInvite":
            guard let id = dict["id"],
                  let password = dict["password"],
                  let hostId = dict["hostId"],
                  let rawColor = dict["hostColor"],
                  let color = Color(rawValue: rawColor) else { return nil }
            self = .acceptSecretInvite(id: id, hostId: hostId, hostColor: color, password: password)
        case "getSecretGameResult":
            guard let id = dict["id"], let signature = dict["signature"] else { return nil }
            var params = dict
            params.removeValue(forKey: "id")
            params.removeValue(forKey: "signature")
            params.removeValue(forKey: "type")
            self = .getSecretGameResult(id: id, signature: signature, params: params)
        default:
            return nil
        }
    }
    
}
