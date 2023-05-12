// Copyright © 2023 super metal mons. All rights reserved.

import FirebaseCore
import FirebaseAuth

class Firebase {
    
    static var userId: String?
    
    static func setup() {
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
