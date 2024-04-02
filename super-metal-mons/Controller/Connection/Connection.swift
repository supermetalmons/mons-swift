// ∅ 2024 super-metal-mons

import FirebaseDatabase

protocol ConnectionDelegate: AnyObject {
    
    func didUpdate(opponentMatch: PlayerMatch)
    func didRecover(myMatch: PlayerMatch)
    func enterWatchOnlyMode()
    func didSeeIncompatibleVersion(_ version: IncompatibleVersion)
    
}

class Connection {
    
    var didReconnect = false
    
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
        
        let match = PlayerMatch(version: version, color: hostColor, emojiId: emojiId, fen: fen, status: .waiting)
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

    func joinGame(version: Int, id: String, emojiId: Int, retryCount: Int = 0) {
        guard let userId = userId, retryCount < 3 else {
            // TODO: retry login
            return
        }
        
        database.child("invites/\(id)").getData { [weak self] _, snapshot in
            guard let value = snapshot?.value, let invite = try? GameInvite(dict: value) else { return }
            
            guard invite.version == version else {
                let incompatibleVersion: IncompatibleVersion
                if invite.version < version {
                    incompatibleVersion = .askOpponentToUpdate
                } else {
                    incompatibleVersion = .shouldUpdate
                }
                DispatchQueue.main.async { self?.connectionDelegate?.didSeeIncompatibleVersion(incompatibleVersion) }
                return
            }
                        
            guard invite.hostId != userId else {
                self?.reenterAsHost(invite: invite, id: id)
                return
            }
            
            if invite.guestId == nil {
                self?.database.child("invites/\(id)/guestId").setValue(userId) { error, _ in
                    if error != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                            self?.joinGame(version: version, id: id, emojiId: emojiId, retryCount: retryCount + 1)
                        }
                    } else {
                        self?.getOpponentsMatch(id: id, emojiId: emojiId, invite: invite, createOwnMatch: true)
                    }
                }
            } else if invite.guestId == userId {
                self?.rejoinAsGuest(invite: invite, id: id, lowPriorityEmojiId: emojiId)
            } else if let guestId = invite.guestId {
                self?.watchMatch(id: id, hostId: invite.hostId, guestId: guestId)
            }
        }
    }
    
    private func reenterAsHost(invite: GameInvite, id: String) {
        guard let userId = userId else { return }
        let matchPath = "players/\(userId)/matches/\(id)"
        database.child(matchPath).getData { [weak self] _, snapshot in
            guard let value = snapshot?.value, let myMatch = try? PlayerMatch(dict: value) else { return }
            guard !myMatch.isIncompatibleFormat else {
                DispatchQueue.main.async { self?.connectionDelegate?.didSeeIncompatibleVersion(.unknown) }
                return
            }
            self?.myMatch = myMatch
            self?.didReconnect = true
            DispatchQueue.main.async {
                self?.connectionDelegate?.didRecover(myMatch: myMatch)
            }
            
            if let guestId = invite.guestId, !guestId.isEmpty {
                self?.observe(gameId: id, playerId: guestId)
            } else {
                let invitePath = "invites/\(id)"
                let invitesObserverId = self?.database.child(invitePath).observe(.value) { (snapshot, error) in
                    guard let dict = snapshot.value as? [String: AnyObject], let invite = try? GameInvite(dict: dict) else { return }
                    // TODO: stop observing invite after gettin all necessary data from there
                    guard let guestId = invite.guestId, !guestId.isEmpty else { return }
                    self?.observe(gameId: id, playerId: guestId)
                }
                if let invitesObserverId = invitesObserverId {
                    self?.addObserver(id: invitesObserverId, path: invitePath)
                }
            }
        }
    }
    
    private func rejoinAsGuest(invite: GameInvite, id: String, lowPriorityEmojiId: Int) {
        guard let userId = userId else { return }
        let matchPath = "players/\(userId)/matches/\(id)"
        database.child(matchPath).getData { [weak self] error, snapshot in
            guard let value = snapshot?.value, let myMatch = try? PlayerMatch(dict: value) else {
                if error == nil {
                    self?.getOpponentsMatch(id: id, emojiId: lowPriorityEmojiId, invite: invite, createOwnMatch: true)
                }
                return
            }
            guard !myMatch.isIncompatibleFormat else {
                DispatchQueue.main.async { self?.connectionDelegate?.didSeeIncompatibleVersion(.unknown) }
                return
            }
            self?.myMatch = myMatch
            self?.didReconnect = true
            DispatchQueue.main.async {
                self?.connectionDelegate?.didRecover(myMatch: myMatch)
            }
            self?.getOpponentsMatch(id: id, emojiId: myMatch.emojiId, invite: invite, createOwnMatch: false)
        }
    }
    
    private func watchMatch(id: String, hostId: String, guestId: String) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionDelegate?.enterWatchOnlyMode()
        }
        observe(gameId: id, playerId: hostId)
        observe(gameId: id, playerId: guestId)
    }
    
    private func getOpponentsMatch(id: String, emojiId: Int, invite: GameInvite, createOwnMatch: Bool) {
        guard let userId = userId else { return }
        
        // TODO: validate opponent's match. make sure my match is not created yet.
        database.child("players/\(invite.hostId)/matches/\(id)").getData { [weak self] _, snapshot in
            guard let value = snapshot?.value, let opponentsMatch = try? PlayerMatch(dict: value) else { return }
            guard !opponentsMatch.isIncompatibleFormat else {
                DispatchQueue.main.async { self?.connectionDelegate?.didSeeIncompatibleVersion(.askOpponentToUpdate) }
                return
            }
            
            if createOwnMatch {
                let match = PlayerMatch(version: invite.version, color: invite.hostColor.other, emojiId: emojiId, fen: opponentsMatch.fen, status: .playing)
                self?.myMatch = match
                self?.database.child("players/\(userId)/matches/\(id)").setValue(match.dict) // TODO: make sure it was set. retry if it was not
            }
            
            self?.observe(gameId: id, playerId: invite.hostId)
        }
    }
    
    private func observe(gameId: String, playerId: String) {
        let matchPath = "players/\(playerId)/matches/\(gameId)"
        let observerId = database.child(matchPath).observe(.value) { [weak self] (snapshot, _) in
            guard let dict = snapshot.value as? [String: AnyObject], let match = try? PlayerMatch(dict: dict) else { return }
            guard !match.isIncompatibleFormat else {
                DispatchQueue.main.async { self?.connectionDelegate?.didSeeIncompatibleVersion(.askOpponentToUpdate) }
                return
            }
            
            DispatchQueue.main.async {
                self?.connectionDelegate?.didUpdate(opponentMatch: match)
            }
        }
        addObserver(id: observerId, path: matchPath)
    }
    
}
