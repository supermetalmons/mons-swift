// ∅ 2024 super-metal-mons

import UIKit
import FirebaseDatabase

class SecretRequestProcessor {
    
    private lazy var database = Database.database().reference()
    
    private var userId: String? {
        return Firebase.userId
    }
    
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
        case let .acceptSecretInvite(id, hostId, hostColor, password):
            acceptSecretInvite(id: id, hostId: hostId, hostColor: hostColor, password: password)
        case let .getSecretGameResult(id, signature):
            getSecretGameResult(id: id, signature: signature)
        }
    }
    
    private func createSecretInvite() {
        guard let userId = userId else {
            respondWithError()
            return
        }
        
        let color = Color.random
        let id = String.newGameId
        let emojiId = Images.randomEmojiId
        
        let invite = GameInvite(version: monsGameControllerVersion, hostId: userId, hostColor: color, guestId: nil, password: UUID().uuidString)
        let match = PlayerMatch(version: monsGameControllerVersion, color: color, emojiId: emojiId, fen: MonsGame().fen, status: .waiting)
        
        database.child("invites/\(id)").setValue(invite.dict) { [weak self] error, _ in
            if error != nil {
                self?.respondWithError()
            } else {
                self?.database.child("players/\(userId)/matches/\(id)").setValue(match.dict) { error, _ in
                    if error != nil {
                        self?.respondWithError()
                    } else if let request = self?.request {
                        var response = SecretAppResponse.forRequest(request)
                        
                        response["id"] = id
                        response["hostId"] = userId
                        response["password"] = invite.password
                        response["hostColor"] = color.rawValue
                        
                        self?.respond(response)
                    }
                }
            }
        }
    }
    
    private func recoverSecretInvite(id: String) {
        guard let userId = userId else {
            respondWithError()
            return
        }
        
        database.child("invites/\(id)").getData { [weak self] _, snapshot in
            guard let value = snapshot?.value, let invite = try? GameInvite(dict: value), let password = invite.password, !password.isEmpty else {
                self?.respondWithError()
                return
            }
            
            if let request = self?.request {
                var response = SecretAppResponse.forRequest(request)
                
                response["id"] = id
                response["hostId"] = userId
                response["password"] = password
                response["hostColor"] = invite.hostColor.rawValue
                
                if let guestId = invite.guestId {
                    response["guestId"] = guestId
                }
                
                self?.respond(response)
            }
        }
    }
    
    private func acceptSecretInvite(id: String, hostId: String, hostColor: Color, password: String) {
        guard let userId = userId else {
            respondWithError()
            return
        }
        
        let emojiId = Images.randomEmojiId
        
        let invite = GameInvite(version: monsGameControllerVersion, hostId: hostId, hostColor: hostColor, guestId: userId, password: password)
        let match = PlayerMatch(version: monsGameControllerVersion, color: hostColor.other, emojiId: emojiId, fen: MonsGame().fen, status: .waiting)
        
        database.child("invites/\(id)").setValue(invite.dict) { [weak self] error, _ in
            if error != nil {
                self?.respondWithError()
            } else if let request = self?.request {
                var response = SecretAppResponse.forRequest(request)
                response["guestId"] = userId
                self?.database.child("players/\(userId)/matches/\(id)").setValue(match.dict)
                self?.respond(response)
            }
        }
    }
    
    private func getSecretGameResult(id: String, signature: String) {
        // TODO: winnerId, inviteId, signed(winnerId+inviteId), signature, error, isDraw
    }
    
    private func respondWithError() {
        let response = SecretAppResponse.forRequest(request, error: true)
        respond(response)
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
