// ∅ 2024 super-metal-mons

import Foundation

struct Strings {
    
    static let ok = loc("ok")
    static let cancel = loc("cancel")
    static let thereIsNoLink = loc("there is no link")
    static let copy = loc("copy")
    static let endTheGameConfirmation = loc("end the game?")
    static let opponentLeft = loc("opponent left the game")
    static let somethingIsBroken = loc("sorry, something is broken")
    static let say = loc("say")
    static let rematch = loc("rematch")
    static let lookWithinTheCircle = loc("look within the circle")
    static let claim = loc("claim")
    static let monsRocksGems = loc("mons rocks / gems")
    static let allowLocationAccess = loc("allow location access\nin settings")
    static let thereIsSomethingThere = loc("there might be something there")
    static let search = loc("search")
    static let retry = loc("retry")
    static let couldNotClaim = loc("could not claim")
    static let itMightBeOver = loc("maybe it's over")
    static let youGotTheRock = loc("you got the rock")
    static let show = loc("show")
    static let newLink =  loc("new link")
    static let playHere = loc("play here")
    static let enterLink = loc("enter link")
    
    private static func loc(_ string: String.LocalizationValue) -> String {
        return String(localized: string)
    }
    
}
