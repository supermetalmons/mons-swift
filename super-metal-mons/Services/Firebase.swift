// ∅ 2024 super-metal-mons

import FirebaseCore
import FirebaseAuth

class BaseFirebase {
    
    static var userId: String?
    
    static func auth(competion: ((Bool) -> Void)? = nil) {
        Auth.auth().signInAnonymously { authResult, _ in
            if let user = authResult?.user {
                self.userId = user.uid
            }
        }
    }
    
    static func baseSetup() {
        FirebaseApp.configure()
        auth()
    }
    
}

#if !targetEnvironment(macCatalyst)
import FirebaseAppCheck
import FirebaseFirestore

class Firebase: BaseFirebase {
    
    static func setup() {
        AppCheck.setAppCheckProviderFactory(MonsAppCheckProviderFactory())
        baseSetup()
        Task {
            await checkFirestore()
        }
    }
    
    static func checkFirestore() async {
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("test").getDocuments()
            for document in snapshot.documents {
                NSLog("\(document.documentID) => \(document.data())")
            }
        } catch {
            NSLog("Error getting documents: \(error)")
        }
    }
    
}

private class MonsAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return AppAttestProvider(app: app)
    }
    
}

#else

class Firebase: BaseFirebase {
    
    static func setup() {
        baseSetup()
    }
    
}

#endif
