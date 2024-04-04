// ∅ 2024 super-metal-mons

import UIKit
import FirebaseDatabase

class SecretRequestProcessor {
    
    private let request: SecretAppRequest
    private let onSuccess: () -> Void
    
    init(request: SecretAppRequest, onSuccess: @escaping () -> Void) {
        self.request = request
        self.onSuccess = onSuccess
    }
    
    func cancel() {
        let response = SecretAppResponse.forRequest(request, cancel: true)
        respond(response)
    }
    
    func process() {
        switch request {
        case .createSecretInvite:
            break
            // TODO: inviteId, playerId, password
        case let .recoverSecretInvite(id):
            break
            // TODO: inviteId, playerId, password, opponentId?
        case let .acceptSecretInvite(id, password):
            break
            // TODO: inviteId, playerId, opponentId
        case let .getSecretGameResult(id, signature):
            break
            // TODO: winnerId, inviteId, signed(winnerId+inviteId), signature, error
        }
        
        // TODO: development tmp
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) { [weak self] in
            if let request = self?.request {
                let response = SecretAppResponse.forRequest(request, cancel: false)
                self?.respond(response)
                self?.onSuccess()
            }
        }
    }
    
    private func respond(_ dict: [String: String]) {
        var components = URLComponents(string: "https://\(URL.baseMonsRehab)/app-response")
        components?.queryItems = dict.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components?.url else { return }
        UIApplication.shared.open(url)
    }
    
}
