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
        open("https://mons.rehab/app-response?cancel=true")
        // TODO: mirror original request as well
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
            self?.open("https://mons.rehab/app-response?ok=true")
            self?.onSuccess()
        }
    }
    
    private func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
}
