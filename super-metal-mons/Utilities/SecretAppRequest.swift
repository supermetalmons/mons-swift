// ∅ 2024 super-metal-mons

import Foundation

enum SecretAppRequest {
    
    case createSecretInvite(phr: Bool)
    case recoverSecretInvite(phr: Bool, id: String)
    case acceptSecretInvite(phr: Bool, id: String, hostId: String, hostColor: Color, password: String)
    case getSecretGameResult(phr: Bool, id: String, signature: String, params: [String: String])
    
    var phr: Bool {
#if targetEnvironment(macCatalyst)
        return false
#else
        switch self {
        case .createSecretInvite(let phr), .recoverSecretInvite(let phr, _), .acceptSecretInvite(let phr, _, _, _, _), .getSecretGameResult(let phr, _, _, _):
            return phr
        }
#endif
    }
    
    init?(dict: [String: String]) {
        let phr = (dict["phr"] ?? "1") == "1"
        switch dict["type"] {
        case "createSecretInvite":
            self = .createSecretInvite(phr: phr)
        case "recoverSecretInvite":
            guard let id = dict["id"] else { return nil }
            self = .recoverSecretInvite(phr: phr, id: id)
        case "acceptSecretInvite":
            guard let id = dict["id"],
                  let password = dict["password"],
                  let hostId = dict["hostId"],
                  let rawColor = dict["hostColor"],
                  let color = Color(rawValue: rawColor) else { return nil }
            self = .acceptSecretInvite(phr: phr, id: id, hostId: hostId, hostColor: color, password: password)
        case "getSecretGameResult":
            guard let id = dict["id"], let signature = dict["signature"] else { return nil }
            var params = dict
            params.removeValue(forKey: "id")
            params.removeValue(forKey: "signature")
            params.removeValue(forKey: "type")
            self = .getSecretGameResult(phr: phr, id: id, signature: signature, params: params)
        default:
            return nil
        }
    }
    
}
