// ∅ 2024 super-metal-mons

import FirebaseDatabase

protocol ConnectionDelegate: AnyObject {
    
    func didUpdate(match: PlayerMatch)
    func enterWatchOnlyMode()
    
}

class Connection {
    
    private let gameId: String
    private lazy var database = Database.database().reference()
    private var observers = [UInt: String]()
    private weak var connectionDelegate: ConnectionDelegate? = nil
    
    private var userId: String? {
        return Firebase.userId
    }
    
    private var myMatch: PlayerMatch?
    
    init(gameId: String) {
        self.gameId = gameId
    }
    
    func setDelegate(_ delegate: ConnectionDelegate) {
        connectionDelegate = delegate
    }
    
    deinit {
        observers.forEach { id, path in
            database.child(path).removeObserver(withHandle: id)
        }
    }
    
    private func addObserver(id: UInt, path: String) {
        observers[id] = path
    }
    
    func addInvite(id: String, version: Int, hostColor: Color, emojiId: Int, fen: String) {
        guard let userId = userId else {
            // TODO: retry login
            return
        }
        let invite = GameInvite(version: version, hostId: userId, hostColor: hostColor, guestId: nil)
        database.child("invites/\(id)").setValue(invite.dict) // TODO: validate it was actually set, retry if not
        
        let match = PlayerMatch(color: hostColor, emojiId: emojiId, fen: fen, status: .waiting)
        myMatch = match
        database.child("players/\(userId)/matches/\(id)").setValue(match.dict) // TODO: validate it was actually set, retry if not
        
        let invitePath = "invites/\(id)"
        let invitesObserverId = database.child(invitePath).observe(.value) { [weak self] (snapshot, error) in
            guard let dict = snapshot.value as? [String: AnyObject], let invite = try? GameInvite(dict: dict) else { return }
            
            // TODO: stop observing invite after gettin all necessary data from there
            
            guard let guestId = invite.guestId, !guestId.isEmpty else { return }
            self?.observe(gameId: id, playerId: guestId)
        }
        
        addObserver(id: invitesObserverId, path: invitePath)
    }
    
    func makeMove(inputs: [Input], newFen: String) {
        myMatch?.fen = newFen
        var moves = myMatch?.moves ?? []
        moves.append(inputs)
        myMatch?.moves = moves
        guard let userId = userId, let myMatch = myMatch else { return }
        database.child("players/\(userId)/matches/\(gameId)").setValue(myMatch.dict)
    }
    
    func react(_ reaction: Reaction) {
        myMatch?.reaction = reaction
        guard let userId = userId, let myMatch = myMatch else { return }
        database.child("players/\(userId)/matches/\(gameId)").setValue(myMatch.dict)
    }
    
    func updateEmoji(id: Int) {
        myMatch?.emojiId = id
        guard let userId = userId, let myMatch = myMatch else { return }
        database.child("players/\(userId)/matches/\(gameId)").setValue(myMatch.dict)
    }
    
    func updateStatus(_ status: PlayerMatch.Status) {
        myMatch?.status = status
        guard let userId = userId, let myMatch = myMatch else { return }
        database.child("players/\(userId)/matches/\(gameId)").setValue(myMatch.dict)
    }

    func joinGame(id: String, emojiId: Int, retryCount: Int = 0) {
        guard let userId = userId, retryCount < 3 else {
            // TODO: retry login
            return
        }
        
        database.child("invites/\(id)").getData { [weak self] _, snapshot in
            guard let value = snapshot?.value, let invite = try? GameInvite(dict: value) else { return }
            // TODO: check invite version number. stop if invite version is not supported
            
            guard invite.hostId != userId else {
                // TODO: if i am host, reconfigure screen as a waiting host or get back to the game
                return
            }
            
            if invite.guestId == nil {
                self?.database.child("invites/\(id)/guestId").setValue(userId) { error, _ in
                    if error != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                            self?.joinGame(id: id, emojiId: emojiId, retryCount: retryCount + 1)
                        }
                    } else {
                        self?.getOpponentsMatchAndCreateOwnMatch(id: id, userId: userId, emojiId: emojiId, invite: invite)
                    }
                }
            } else if invite.guestId == userId {
                // TODO: did join already, get game info and proceed from there
            } else if let guestId = invite.guestId {
                self?.watchMatch(id: id, hostId: invite.hostId, guestId: guestId)
            }
        }
    }
    
    private func watchMatch(id: String, hostId: String, guestId: String) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionDelegate?.enterWatchOnlyMode()
        }
        observe(gameId: id, playerId: hostId)
        observe(gameId: id, playerId: guestId)
    }
    
    private func getOpponentsMatchAndCreateOwnMatch(id: String, userId: String, emojiId: Int, invite: GameInvite) {
        // TODO: validate opponent's match. make sure my match is not created yet.
        database.child("players/\(invite.hostId)/matches/\(id)").getData { [weak self] _, snapshot in
            // TODO: detect incompatible PlayerMatch model here
            guard let value = snapshot?.value, let opponentsMatch = try? PlayerMatch(dict: value) else { return }
            let match = PlayerMatch(color: invite.hostColor.other, emojiId: emojiId, fen: opponentsMatch.fen, status: .playing)
            self?.myMatch = match
            self?.database.child("players/\(userId)/matches/\(id)").setValue(match.dict) // TODO: make sure it was set. retry if it was not
            self?.observe(gameId: id, playerId: invite.hostId)
        }
    }
    
    private func observe(gameId: String, playerId: String) {
        let matchPath = "players/\(playerId)/matches/\(gameId)"
        let observerId = database.child(matchPath).observe(.value) { [weak self] (snapshot, _) in
            // TODO: detect incompatible PlayerMatch model here
            guard let dict = snapshot.value as? [String: AnyObject], let match = try? PlayerMatch(dict: dict) else { return }
            DispatchQueue.main.async {
                self?.connectionDelegate?.didUpdate(match: match)
            }
        }
        addObserver(id: observerId, path: matchPath)
    }
    
}
