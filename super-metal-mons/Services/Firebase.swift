// ∅ 2024 super-metal-mons

import FirebaseAppCheck
import FirebaseCore
import FirebaseAuth

class Firebase {
    
    static var userId: String?
    
    static func setup() {
        AppCheck.setAppCheckProviderFactory(MonsAppCheckProviderFactory())
        FirebaseApp.configure()
        auth()
    }
    
    static func auth(competion: ((Bool) -> Void)? = nil) {
        Auth.auth().signInAnonymously { authResult, _ in
            if let user = authResult?.user {
                self.userId = user.uid
            }
        }
    }
    
}

private class MonsAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return AppAttestProvider(app: app)
    }
    
}
