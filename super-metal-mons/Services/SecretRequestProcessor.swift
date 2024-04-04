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
            break // TODO: implement
        case .recoverSecretInvite(id: let id):
            break // TODO: implement
        case .acceptSecretInvite(id: let id, password: let password):
            break // TODO: implement
        case .getSecretGameResult(id: let id, signature: let signature):
            break // TODO: implement
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
