// Copyright © 2023 super metal mons. All rights reserved.

import FirebaseDatabase

protocol GameDataSource {
    var gameId: String { get }
    func observe(completion: @escaping (String) -> Void)
    func update(fen: String)
}

class RemoteGameDataSource: GameDataSource {
    
    private let database = Database.database().reference()
    private var lastSharedFen = ""
    
    let gameId: String
    
    init(gameId: String) {
        self.gameId = gameId
    }
    
    func observe(completion: @escaping (String) -> Void) {
        database.child(gameId).observe(.value) { [weak self] (snapshot, _) in
            guard let data = snapshot.value as? [String: AnyObject], let fen = data["fen"] as? String else {
                print("No fen found")
                return
            }
            
            guard self?.lastSharedFen != fen, !fen.isEmpty else { return }
            completion(fen)
        }
    }
    
    func update(fen: String) {
        guard lastSharedFen != fen else { return }
        database.child(gameId).setValue(["fen": fen])
        lastSharedFen = fen
    }
    
}

class LocalGameDataSource: GameDataSource {
    
    let gameId: String
    
    init(gameId: String) {
        self.gameId = gameId
    }
    
    func observe(completion: @escaping (String) -> Void) {}
    
    func update(fen: String) { }
    
}
