// ∅ 2024 super-metal-mons

import FirebaseCore
import FirebaseAuth
import FirebaseAppCheck
import FirebaseFirestore

class Firebase {
    
    static var userId: String?
    
    static func setup() {
        AppCheck.setAppCheckProviderFactory(MonsAppCheckProviderFactory())
        FirebaseApp.configure()
        auth()
        
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
