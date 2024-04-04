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
        respond(response, isCancel: true)
    }
    
    func process() {
        switch request {
        case .createSecretInvite:
            createSecretInvite()
        case let .recoverSecretInvite(id):
            recoverSecretInvite(id: id)
        case let .acceptSecretInvite(id, password):
            acceptSecretInvite(id: id, password: password)
        case let .getSecretGameResult(id, signature):
            getSecretGameResult(id: id, signature: signature)
        }
    }
    
    private func createSecretInvite() {
        // TODO: inviteId, playerId, password
        let response = SecretAppResponse.forRequest(request)
        respond(response)
    }
    
    private func recoverSecretInvite(id: String) {
        // TODO: inviteId, playerId, password, opponentId?
    }
    
    private func acceptSecretInvite(id: String, password: String) {
        // TODO: inviteId, playerId, opponentId
    }
    
    private func getSecretGameResult(id: String, signature: String) {
        // TODO: winnerId, inviteId, signed(winnerId+inviteId), signature, error, isDraw
    }
    
    private func respond(_ dict: [String: String], isCancel: Bool = false) {
        var components = URLComponents(string: "https://\(URL.baseMonsRehab)/app-response")
        components?.queryItems = dict.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components?.url else { return }
        DispatchQueue.main.async { [weak self] in
            UIApplication.shared.open(url)
            if !isCancel {
                self?.onSuccess()
            }
        }
    }
    
}
