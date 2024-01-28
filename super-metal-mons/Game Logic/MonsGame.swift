// ∅ 2024 super-metal-mons

import Foundation

class MonsGame: NSObject {
    
    private(set) var board: Board

    private(set) var whiteScore: Int
    private(set) var blackScore: Int
    private(set) var activeColor: Color
    
    private(set) var actionsUsedCount: Int
    private(set) var manaMovesCount: Int
    private(set) var monsMovesCount: Int
    
    private(set) var whitePotionsCount: Int
    private(set) var blackPotionsCount: Int
    
    private(set) var turnNumber: Int
    
    override init() {
        self.board = Board()
        self.whiteScore = 0
        self.blackScore = 0
        self.activeColor = .white
        self.actionsUsedCount = 0
        self.manaMovesCount = 0
        self.monsMovesCount = 0
        self.whitePotionsCount = 0
        self.blackPotionsCount = 0
        self.turnNumber = 1
        super.init()
    }
    
    init(board: Board,
         whiteScore: Int,
         blackScore: Int,
         activeColor: Color,
         actionsUsedCount: Int,
         manaMovesCount: Int,
         monsMovesCount: Int,
         whitePotionsCount: Int,
         blackPotionsCount: Int,
         turnNumber: Int) {
        self.board = board
        self.whiteScore = whiteScore
        self.blackScore = blackScore
        self.activeColor = activeColor
        self.actionsUsedCount = actionsUsedCount
        self.manaMovesCount = manaMovesCount
        self.monsMovesCount = monsMovesCount
        self.whitePotionsCount = whitePotionsCount
        self.blackPotionsCount = blackPotionsCount
        self.turnNumber = turnNumber
    }
    
    func updateWith(otherGame: MonsGame) {
        board = Board(items: otherGame.board.items)
            
        whiteScore = otherGame.whiteScore
        blackScore = otherGame.blackScore
        activeColor = otherGame.activeColor
        
        actionsUsedCount = otherGame.actionsUsedCount
        manaMovesCount = otherGame.manaMovesCount
        monsMovesCount = otherGame.monsMovesCount
        
        whitePotionsCount = otherGame.whitePotionsCount
        blackPotionsCount = otherGame.blackPotionsCount
        
        turnNumber = otherGame.turnNumber
    }

    // MARK: - process input
    
    func processInput(_ input: [Input], doNotApplyEvents: Bool) -> Output {
        guard winnerColor == nil else { return .invalidInput }
        guard !input.isEmpty else { return suggestedInputToStartWith() }
        guard case let .location(startLocation) = input[0], let startItem = board.item(at: startLocation) else { return .invalidInput }
        let oneSecondOptionIsEnough = input.count == 1 && doNotApplyEvents
        let secondInputOptions = secondInputOptions(startLocation: startLocation, startItem: startItem, onlyOne: oneSecondOptionIsEnough)
        
        guard input.count > 1 else {
            if secondInputOptions.isEmpty {
                return .invalidInput
            } else {
                return .nextInputOptions(secondInputOptions)
            }
        }
        
        let secondInput = input[1]
        guard case let .location(targetLocation) = secondInput else { return .invalidInput }
        guard let secondInputKind = secondInputOptions.first(where: { $0.input == secondInput })?.kind else { return .invalidInput }
        
        let outputForSecondInput = processSecondInput(kind: secondInputKind, startItem: startItem, startLocation: startLocation, targetLocation: targetLocation)
        let thirdInputOptions = outputForSecondInput?.1 ?? []
        var events = outputForSecondInput?.0 ?? []
        
        guard input.count > 2 else {
            if !thirdInputOptions.isEmpty {
                return .nextInputOptions(thirdInputOptions)
            } else if !events.isEmpty {
                return .events(doNotApplyEvents ? events : applyAndAddResultingEvents(to: events))
            } else {
                return .invalidInput
            }
        }
        
        guard let thirdInput = thirdInputOptions.first(where: { $0.input == input[2] }) else { return .invalidInput }
         
        let outputForThirdInput = processThirdInput(thirdInput, startItem: startItem, startLocation: startLocation, targetLocation: targetLocation)
        let forthInputOptions = outputForThirdInput?.1 ?? []
        events += (outputForThirdInput?.0 ?? [])
        
        guard input.count > 3 else {
            guard outputForThirdInput != nil else { return .invalidInput }
            if !forthInputOptions.isEmpty {
                return .nextInputOptions(forthInputOptions)
            } else if !events.isEmpty {
                return .events(doNotApplyEvents ? events : applyAndAddResultingEvents(to: events))
            } else {
                return .invalidInput
            }
        }
        
        guard case let .modifier(modifier) = input[3] else { return .invalidInput }
        guard let forthInput = forthInputOptions.first(where: { $0.input == input[3] }),
              case let .location(destinationLocation) = thirdInput.input,
              let actorMonItem = forthInput.actorMonItem,
              let actorMon = actorMonItem.mon
        else {
            return .invalidInput
        }
        
        switch modifier {
        case .selectBomb:
            events.append(.pickupBomb(by: actorMon, at: destinationLocation))
        case .selectPotion:
            events.append(.pickupPotion(by: actorMonItem, at: destinationLocation))
        case .cancel:
            return .invalidInput
        }
        return .events(doNotApplyEvents ? events : applyAndAddResultingEvents(to: events))
    }
    
    // MARK: - process step by step
    
    private func suggestedInputToStartWith() -> Output {
        let locationsFilter: ((Location) -> Location?) = { [weak self] location in
            let output = self?.processInput([.location(location)], doNotApplyEvents: true)
            if case let .nextInputOptions(options) = output, !options.isEmpty {
                return location
            } else {
                return nil
            }
        }
        
        var suggestedLocations = board.allMonsLocations(color: activeColor).compactMap(locationsFilter)
        if (!playerCanMoveMon && !playerCanUseAction || suggestedLocations.isEmpty) && playerCanMoveMana {
            suggestedLocations.append(contentsOf: board.allFreeRegularManaLocations(color: activeColor).compactMap(locationsFilter))
        }
        
        if suggestedLocations.isEmpty {
            return .invalidInput
        } else {
            return .locationsToStartFrom(suggestedLocations)
        }
    }
    
    private func secondInputOptions(startLocation: Location, startItem: Item, onlyOne: Bool) -> [NextInput] {
        let startSquare = board.square(at: startLocation)
        var secondInputOptions = [NextInput]()
        switch startItem {
        case .mon(let mon):
            guard mon.color == activeColor, !mon.isFainted else { return [] }

            if playerCanMoveMon {
                secondInputOptions += nextInputs(startLocation.nearbyLocations, kind: .monMove, onlyOne: onlyOne) { location in
                    let item = board.item(at: location)
                    let square = board.square(at: location)
                    
                    if let item = item {
                        switch item {
                        case .mon, .monWithMana, .monWithConsumable:
                            return false
                        case .mana:
                            if mon.kind == .drainer {
                                break
                            } else {
                                return false
                            }
                        case .consumable:
                            break
                        }
                    }
                    
                    switch square {
                    case .regular, .consumableBase, .manaBase, .manaPool:
                        return true
                    case .supermanaBase:
                        return item == .mana(mana: .supermana) && mon.kind == .drainer
                    case .monBase(let kind, let color):
                        return mon.kind == kind && mon.color == color
                    }
                }
                
                if onlyOne && !secondInputOptions.isEmpty { return secondInputOptions }
            }
            
            if case .monBase = startSquare {
                // can't use action from the base
            } else if playerCanUseAction {
                switch mon.kind {
                case .angel, .drainer:
                    break
                case .mystic:
                    secondInputOptions += nextInputs(startLocation.reachableByMysticAction, kind: .mysticAction, onlyOne: onlyOne) { location -> Bool in
                        guard let item = board.item(at: location), !protectedByOpponentsAngel.contains(location) else { return false }
                        
                        switch item {
                        case let .mon(targetMon), let .monWithMana(targetMon, _), let .monWithConsumable(targetMon, _):
                            if mon.color == targetMon.color || targetMon.isFainted {
                                return false
                            }
                        case .mana, .consumable:
                            return false
                        }
                        
                        return true
                    }
                case .demon:
                    secondInputOptions += nextInputs(startLocation.reachableByDemonAction, kind: .demonAction, onlyOne: onlyOne) { location -> Bool in
                        guard let item = board.item(at: location), !protectedByOpponentsAngel.contains(location) else { return false }
                        let locationBetween = startLocation.locationBetween(another: location)
                        guard board.item(at: locationBetween) == nil else { return false }
                        
                        switch item {
                        case .mon(let targetMon), let .monWithMana(targetMon, _), let .monWithConsumable(targetMon, _):
                            if mon.color == targetMon.color || targetMon.isFainted {
                                return false
                            }
                        case .mana, .consumable:
                            return false
                        }
                        
                        return true
                    }
                case .spirit:
                    secondInputOptions += nextInputs(startLocation.reachableBySpiritAction, kind: .spiritTargetCapture, onlyOne: onlyOne) { location -> Bool in
                        guard let item = board.item(at: location) else { return false }
                        
                        switch item {
                        case .mon(let targetMon), let .monWithMana(targetMon, _), let .monWithConsumable(targetMon, _):
                            if targetMon.isFainted { return false }
                        case .mana, .consumable:
                            break
                        }
                        
                        return true
                    }
                }
            }
            
        case .mana(let mana):
            guard case let .regular(color) = mana, color == activeColor, playerCanMoveMana else { return [] }
            
            secondInputOptions += nextInputs(startLocation.nearbyLocations, kind: .manaMove, onlyOne: onlyOne) { location in
                let item = board.item(at: location)
                let square = board.square(at: location)
                
                if let item = item {
                    switch item {
                    case .mon(let mon):
                        if mon.kind == .drainer {
                            break
                        } else {
                            return false
                        }
                    case .monWithConsumable, .consumable, .monWithMana, .mana:
                        return false
                    }
                }
                
                switch square {
                case .regular, .consumableBase, .manaBase, .manaPool:
                    return true
                case .supermanaBase, .monBase:
                    return false
                }
            }
            
        case .monWithMana(let mon, let mana):
            guard mon.color == activeColor, playerCanMoveMon else { return [] }
            
            secondInputOptions += nextInputs(startLocation.nearbyLocations, kind: .monMove, onlyOne: onlyOne) { location in
                let item = board.item(at: location)
                let square = board.square(at: location)
                
                if let item = item {
                    switch item {
                    case .mon, .monWithMana, .monWithConsumable:
                        return false
                    case .consumable, .mana:
                        break
                    }
                }
                
                switch square {
                case .regular, .consumableBase, .manaBase, .manaPool:
                    return true
                case .supermanaBase:
                    return mana == .supermana || item?.mana == .supermana
                case .monBase:
                    return false
                }
            }
                        
        case .monWithConsumable(let mon, let consumable):
            guard mon.color == activeColor else { return [] }
            
            if playerCanMoveMon {
                secondInputOptions += nextInputs(startLocation.nearbyLocations, kind: .monMove, onlyOne: onlyOne) { location in
                    let item = board.item(at: location)
                    let square = board.square(at: location)
                    
                    if let item = item {
                        switch item {
                        case .mon, .mana, .monWithMana, .monWithConsumable:
                            return false
                        case .consumable:
                            break
                        }
                    }
                    
                    switch square {
                    case .regular, .consumableBase, .manaBase, .manaPool:
                        return true
                    case .supermanaBase, .monBase:
                        return false
                    }
                }
                
                if onlyOne && !secondInputOptions.isEmpty { return secondInputOptions }
            }
            
            if case .bomb = consumable {
                secondInputOptions += nextInputs(startLocation.reachableByBomb, kind: .bombAttack, onlyOne: onlyOne) { location -> Bool in
                    guard let item = board.item(at: location) else { return false }
                    
                    switch item {
                    case let .mon(targetMon), let .monWithMana(targetMon, _), let .monWithConsumable(targetMon, _):
                        if mon.color == targetMon.color || targetMon.isFainted {
                            return false
                        }
                    case .consumable, .mana:
                        return false
                    }
                    
                    return true
                }
            }
        case .consumable:
            return []
        }
        
        return secondInputOptions
    }
    
    private func processSecondInput(kind: NextInput.Kind, startItem: Item, startLocation: Location, targetLocation: Location) -> ([Event], [NextInput])? {
        var thirdInputOptions = [NextInput]()
        var events = [Event]()
        let targetSquare = board.square(at: targetLocation)
        let targetItem = board.item(at: targetLocation)
        
        switch kind {
        case .monMove:
            guard let startMon = startItem.mon else { return nil }
            events.append(.monMove(item: startItem, from: startLocation, to: targetLocation))
            
            if let targetItem = targetItem {
                switch targetItem {
                case .mon, .monWithMana, .monWithConsumable:
                    return nil
                case .mana(let mana):
                    if let startMana = startItem.mana {
                        if case .supermana = startMana {
                            events.append(.supermanaBackToBase(from: startLocation, to: board.supermanaBase))
                        } else {
                            events.append(.manaDropped(mana: startMana, at: startLocation))
                        }
                    }
                    events.append(.pickupMana(mana: mana, by: startMon, at: targetLocation))
                case .consumable(let consumable):
                    switch consumable {
                    case .potion, .bomb:
                        return nil
                    case .bombOrPotion:
                        if startItem.consumable != nil || startItem.mana != nil {
                            events.append(.pickupPotion(by: startItem, at: targetLocation))
                        } else {
                            thirdInputOptions = [
                                NextInput(input: Input.modifier(.selectBomb), kind: .selectConsumable, actorMonItem: startItem),
                                NextInput(input: Input.modifier(.selectPotion), kind: .selectConsumable, actorMonItem: startItem)
                            ]
                        }
                    }
                }
            }
            
            switch targetSquare {
            case .regular, .consumableBase, .supermanaBase, .manaBase, .monBase:
                break
            case .manaPool:
                if let manaInHand = startItem.mana {
                    events.append(.manaScored(mana: manaInHand, at: targetLocation))
                }
            }
            
        case .manaMove:
            guard case let .mana(mana) = startItem else { return nil }
            events.append(.manaMove(mana: mana, from: startLocation, to: targetLocation))
            
            if let targetItem = targetItem {
                switch targetItem {
                case .mon(let mon):
                    events.append(.pickupMana(mana: mana, by: mon, at: targetLocation))
                case .mana, .consumable, .monWithMana, .monWithConsumable:
                    return nil
                }
            }
            
            switch targetSquare {
            case .manaBase, .consumableBase, .regular:
                break
            case .manaPool:
                events.append(.manaScored(mana: mana, at: targetLocation))
            case .monBase, .supermanaBase:
                return nil
            }
        case .mysticAction:
            guard let startMon = startItem.mon, let targetItem = targetItem else { return nil }
            events.append(.mysticAction(mystic: startMon, from: startLocation, to: targetLocation))
            
            switch targetItem {
            case .mon(let targetMon):
                events.append(.monFainted(mon: targetMon, from: targetLocation, to: board.base(mon: targetMon)))
            case .monWithMana(let targetMon, let mana):
                events.append(.monFainted(mon: targetMon, from: targetLocation, to: board.base(mon: targetMon)))
                
                switch mana {
                case .regular:
                    events.append(.manaDropped(mana: mana, at: targetLocation))
                case .supermana:
                    events.append(.supermanaBackToBase(from: targetLocation, to: board.supermanaBase))
                }
            case .monWithConsumable(let targetMon, let consumable):
                events.append(.monFainted(mon: targetMon, from: targetLocation, to: board.base(mon: targetMon)))
                switch consumable {
                case .potion, .bombOrPotion:
                    return nil
                case .bomb:
                    events.append(.bombExplosion(at: targetLocation))
                }
            case .consumable, .mana:
                return nil
            }
            
        case .demonAction:
            guard let startMon = startItem.mon, let targetItem = targetItem else { return nil }
            events.append(.demonAction(demon: startMon, from: startLocation, to: targetLocation))
            var requiresAdditionalStep = false
      
            switch targetItem {
            case .mana, .consumable:
                return nil
            case .mon(let targetMon):
                events.append(.monFainted(mon: targetMon, from: targetLocation, to: board.base(mon: targetMon)))
            case .monWithMana(let targetMon, let mana):
                events.append(.monFainted(mon: targetMon, from: targetLocation, to: board.base(mon: targetMon)))
                switch mana {
                case .regular:
                    requiresAdditionalStep = true
                    events.append(.manaDropped(mana: mana, at: targetLocation))
                case .supermana:
                    events.append(.supermanaBackToBase(from: targetLocation, to: board.supermanaBase))
                }
            case .monWithConsumable(let targetMon, let consumable):
                events.append(.monFainted(mon: targetMon, from: targetLocation, to: board.base(mon: targetMon)))
                switch consumable {
                case .potion, .bombOrPotion:
                    return nil
                case .bomb:
                    events.append(.bombExplosion(at: targetLocation))
                    events.append(.monFainted(mon: startMon, from: targetLocation, to: board.base(mon: startMon)))
                }
            }
            
            switch targetSquare {
            case .regular, .consumableBase, .manaBase, .manaPool:
                break
            case .supermanaBase, .monBase:
                requiresAdditionalStep = true
            }
            
            if requiresAdditionalStep {
                thirdInputOptions += nextInputs(targetLocation.nearbyLocations, kind: .demonAdditionalStep, onlyOne: false) { location in
                    let item = board.item(at: location)
                    let square = board.square(at: location)
                    
                    if let item = item {
                        switch item {
                        case .mon, .mana, .monWithMana, .monWithConsumable:
                            return false
                        case .consumable:
                            break
                        }
                    }
                    
                    switch square {
                    case .regular, .consumableBase, .manaBase, .manaPool:
                        return true
                    case let .monBase(kind, color):
                        return startMon.kind == kind && startMon.color == color
                    case .supermanaBase:
                        return false
                    }
                }
            }
            
        case .spiritTargetCapture:
            guard let targetItem = targetItem else { return nil }
            let targetMon = targetItem.mon
            let targetMana = targetItem.mana
            thirdInputOptions += nextInputs(targetLocation.nearbyLocations, kind: .spiritTargetMove, onlyOne: false) { location in
                let destinationItem = board.item(at: location)
                let destinationSquare = board.square(at: location)
                
                if let destinationItem = destinationItem {
                    switch destinationItem {
                    case .mon(let destinationMon):
                        switch targetItem {
                        case .mon, .monWithMana, .monWithConsumable:
                            return false
                        case .mana:
                            if destinationMon.kind != .drainer || destinationMon.isFainted {
                                return false
                            }
                        case .consumable(let targetConsumable):
                            if targetConsumable != .bombOrPotion {
                                return false
                            }
                        }
                        
                    case .mana:
                        switch targetItem {
                        case .mon(let targetMon):
                            if targetMon.kind != .drainer || targetMon.isFainted {
                                return false
                            }
                        case .consumable, .monWithConsumable, .monWithMana, .mana:
                            return false
                        }
                        
                    case .monWithMana:
                        switch targetItem {
                        case .mon, .monWithMana, .monWithConsumable, .mana:
                            return false
                        case .consumable(let targetConsumable):
                            if targetConsumable != .bombOrPotion {
                                return false
                            }
                        }
                        
                    case .monWithConsumable:
                        switch targetItem {
                        case .mon, .monWithMana, .monWithConsumable, .mana:
                            return false
                        case .consumable(let targetConsumable):
                            if targetConsumable != .bombOrPotion {
                                return false
                            }
                        }
                        
                    case .consumable(let destinationConsumable):
                        switch targetItem {
                        case .mon, .monWithMana, .monWithConsumable:
                            if destinationConsumable != .bombOrPotion {
                                return false
                            }
                        case .mana, .consumable:
                            return false
                        }
                    }
                }
                
                switch destinationSquare {
                case .regular, .consumableBase, .manaBase, .manaPool:
                    return true
                case .supermanaBase:
                    if let mana = targetMana, case .supermana = mana {
                        return true
                    } else if .drainer == targetMon?.kind, destinationItem?.mana == .supermana {
                        return true
                    }
                    else {
                        return false
                    }
                case .monBase(let kind, let color):
                    if targetMon?.kind == kind && targetMon?.color == color && targetMana == nil && targetItem.consumable == nil {
                        return true
                    } else {
                        return false
                    }
                }
            }
            
        case .bombAttack:
            guard let startMon = startItem.mon, let targetItem = targetItem else { return nil }
            events.append(.bombAttack(by: startMon, from: startLocation, to: targetLocation))
            
            switch targetItem {
            case .mon(let mon):
                events.append(.monFainted(mon: mon, from: targetLocation, to: board.base(mon: mon)))
            case .monWithMana(let mon, let mana):
                events.append(.monFainted(mon: mon, from: targetLocation, to: board.base(mon: mon)))
                switch mana {
                case .regular:
                    events.append(.manaDropped(mana: mana, at: targetLocation))
                case .supermana:
                    events.append(.supermanaBackToBase(from: targetLocation, to: board.supermanaBase))
                }
            case .monWithConsumable(let mon, let consumable):
                events.append(.monFainted(mon: mon, from: targetLocation, to: board.base(mon: mon)))
                switch consumable {
                case .potion, .bombOrPotion:
                    return nil
                case .bomb:
                    events.append(.bombExplosion(at: targetLocation))
                }
            case .mana, .consumable:
                return nil
            }

        case .spiritTargetMove, .demonAdditionalStep, .selectConsumable:
            return nil
        }
        
        return (events, thirdInputOptions)
    }
    
    private func processThirdInput(_ thirdInput: NextInput, startItem: Item, startLocation: Location, targetLocation: Location) -> ([Event], [NextInput])? {
        let targetItem = board.item(at: targetLocation)
        var forthInputOptions = [NextInput]()
        var events = [Event]()
        
        switch thirdInput.kind {
        case .monMove, .manaMove, .mysticAction, .demonAction, .spiritTargetCapture, .bombAttack:
            return nil
        case .spiritTargetMove:
            guard case let .location(destinationLocation) = thirdInput.input, let targetItem = targetItem else { return nil }
            let destinationItem = board.item(at: destinationLocation)
            let destinationSquare = board.square(at: destinationLocation)
            
            events.append(.spiritTargetMove(item: targetItem, from: targetLocation, to: destinationLocation))
            
            if let destinationItem = destinationItem {
                
                switch targetItem {
                case .mon(let travellingMon):
                    switch destinationItem {
                    case .mon, .monWithMana, .monWithConsumable:
                        return nil
                    case .mana(let destinationMana):
                        events.append(.pickupMana(mana: destinationMana, by: travellingMon, at: destinationLocation))
                    case .consumable(let destinationConsumable):
                        switch destinationConsumable {
                        case .potion, .bomb:
                            return nil
                        case .bombOrPotion:
                            forthInputOptions = [
                                NextInput(input: Input.modifier(.selectBomb), kind: .selectConsumable, actorMonItem: targetItem),
                                NextInput(input: Input.modifier(.selectPotion), kind: .selectConsumable, actorMonItem: targetItem)
                            ]
                        }
                    }
                    
                case .mana(let travellingMana):
                    switch destinationItem {
                    case .mana, .monWithMana, .monWithConsumable, .consumable:
                        return nil
                    case .mon(let destinationMon):
                        events.append(.pickupMana(mana: travellingMana, by: destinationMon, at: destinationLocation))
                    }
                    
                case .monWithMana:
                    switch destinationItem {
                    case .mon, .mana, .monWithMana, .monWithConsumable:
                        return nil
                    case .consumable(let destinationConsumable):
                        switch destinationConsumable {
                        case .potion, .bomb:
                            return nil
                        case .bombOrPotion:
                            events.append(.pickupPotion(by: targetItem, at: destinationLocation))
                        }
                    }
                    
                case .monWithConsumable:
                    switch destinationItem {
                    case .mon, .mana, .monWithMana, .monWithConsumable:
                        return nil
                    case .consumable(let destinationConsumable):
                        switch destinationConsumable {
                        case .potion, .bomb:
                            return nil
                        case .bombOrPotion:
                            events.append(.pickupPotion(by: targetItem, at: destinationLocation))
                        }
                    }
                    
                case .consumable(let travellingConsumable):
                    switch destinationItem {
                    case .mana, .consumable:
                        return nil
                    case .mon:
                        forthInputOptions = [
                            NextInput(input: Input.modifier(.selectBomb), kind: .selectConsumable, actorMonItem: destinationItem),
                            NextInput(input: Input.modifier(.selectPotion), kind: .selectConsumable, actorMonItem: destinationItem)
                        ]
                    case .monWithMana, .monWithConsumable:
                        switch travellingConsumable {
                        case .potion, .bomb:
                            return nil
                        case .bombOrPotion:
                            events.append(.pickupPotion(by: destinationItem, at: destinationLocation))
                        }
                    }
                }
                
            }
            
            if case .manaPool = destinationSquare, let mana = targetItem.mana {
                events.append(.manaScored(mana: mana, at: destinationLocation))
            }
            
        case .demonAdditionalStep:
            guard case let .location(destinationLocation) = thirdInput.input, let demon = startItem.mon else { return nil }
            events.append(.demonAdditionalStep(demon: demon, from: targetLocation, to: destinationLocation))
            
            if let item = board.item(at: destinationLocation), case .consumable(let consumable) = item {
                switch consumable {
                case .potion, .bomb:
                    return nil
                case .bombOrPotion:
                    forthInputOptions = [
                        NextInput(input: Input.modifier(.selectBomb), kind: .selectConsumable, actorMonItem: startItem),
                        NextInput(input: Input.modifier(.selectPotion), kind: .selectConsumable, actorMonItem: startItem)
                    ]
                }
            }
            
        case .selectConsumable:
            guard case let .modifier(modifier) = thirdInput.input, let mon = startItem.mon else { return nil }
            switch modifier {
            case .selectBomb:
                events.append(.pickupBomb(by: mon, at: targetLocation))
            case .selectPotion:
                events.append(.pickupPotion(by: startItem, at: targetLocation))
            case .cancel:
                return nil
            }
        }
        
        return (events, forthInputOptions)
    }
    
    // MARK: - apply events
    
    private func applyAndAddResultingEvents(to events: [Event]) -> [Event] {
        func didUseAction() {
            if actionsUsedCount >= Config.actionsPerTurn {
                switch activeColor {
                case .white:
                    whitePotionsCount -= 1
                case .black:
                    blackPotionsCount -= 1
                }
            } else {
                actionsUsedCount += 1
            }
        }
        
        for event in events {
            switch event {
            case .monMove(let item, let from, let to):
                monsMovesCount += 1
                board.removeItem(location: from)
                board.put(item: item, location: to)
            case .manaMove(let mana, let from, let to):
                manaMovesCount += 1
                board.removeItem(location: from)
                board.put(item: .mana(mana: mana), location: to)
            case .manaScored(let mana, let at):
                switch activeColor {
                case .black:
                    blackScore += mana.score(for: activeColor)
                case .white:
                    whiteScore += mana.score(for: activeColor)
                }
                
                if let mon = board.item(at: at)?.mon {
                    board.put(item: .mon(mon: mon), location: at)
                } else {
                    board.removeItem(location: at)
                }
                
            case .mysticAction(_, _, let to):
                didUseAction()
                board.removeItem(location: to)
            case let .demonAction(demon, from, to):
                didUseAction()
                board.removeItem(location: from)
                board.put(item: .mon(mon: demon), location: to)
            case .demonAdditionalStep(let demon, _, let to):
                board.put(item: .mon(mon: demon), location: to)
            case .spiritTargetMove(let item, let from, let to):
                didUseAction()
                board.removeItem(location: from)
                board.put(item: item, location: to)
            case .pickupBomb(let by, let at):
                board.put(item: .monWithConsumable(mon: by, consumable: .bomb), location: at)
            case .pickupPotion(let by, let at):
                if let color = by.mon?.color {
                    switch color {
                    case .black:
                        blackPotionsCount += 1
                    case .white:
                        whitePotionsCount += 1
                    }
                }
                board.put(item: by, location: at)
            case .pickupMana(let mana, let by, let at):
                board.put(item: .monWithMana(mon: by, mana: mana), location: at)
            case .monFainted(var mon, _, let to):
                mon.faint()
                board.put(item: .mon(mon: mon), location: to)
            case .manaDropped(let mana, let at):
                board.put(item: .mana(mana: mana), location: at)
            case .supermanaBackToBase(_, let to):
                board.put(item: .mana(mana: .supermana), location: to)
            case let .bombAttack(by, from, to):
                board.removeItem(location: to)
                board.put(item: .mon(mon: by), location: from)
            case .bombExplosion(let at):
                board.removeItem(location: at)
            case .monAwake, .gameOver, .nextTurn:
                break
            }
        }
        
        var extraEvents = [Event]()
        
        if let winner = winnerColor {
            extraEvents.append(.gameOver(winner: winner))
        } else if isFirstTurn && !playerCanMoveMon ||
            !isFirstTurn && !playerCanMoveMana ||
            !isFirstTurn && !playerCanMoveMon && board.findMana(color: activeColor) == nil {
            activeColor = activeColor == .white ? .black : .white
            turnNumber += 1
            extraEvents.append(.nextTurn(color: activeColor))
            actionsUsedCount = 0
            manaMovesCount = 0
            monsMovesCount = 0
            
            for monLocation in board.faintedMonsLocations(color: activeColor) {
                if var mon = board.item(at: monLocation)?.mon {
                    mon.decreaseCooldown()
                    board.put(item: .mon(mon: mon), location: monLocation)
                    if !mon.isFainted {
                        extraEvents.append(.monAwake(mon: mon, at: monLocation))
                    }
                }
            }
        }

        return events + extraEvents
    }
    
    // MARK: - helpers
    
    func nextInputs(_ locations: [Location], kind: NextInput.Kind, onlyOne: Bool, filter: ((Location) -> Bool)) -> [NextInput] {
        if onlyOne {
            if let one = locations.first(where: filter) {
                return [NextInput(input: .location(one), kind: kind) ]
            } else {
                return []
            }
        } else {
            return locations.compactMap { filter($0) ? NextInput(input: .location($0), kind: kind) : nil }
        }
    }
    
    var availableMoveKinds: [AvailableMoveKind: Int] {
        var moves: [AvailableMoveKind: Int] = [
            .monMove: Config.monsMovesPerTurn - monsMovesCount,
            .action: 0,
            .potion: 0,
            .manaMove: 0
        ]

        if turnNumber == 1 {
            return moves
        }
        
        moves[.action] = (Config.actionsPerTurn - actionsUsedCount)
        moves[.potion] = playerPotionsCount
        moves[.manaMove] = Config.manaMovesPerTurn - manaMovesCount
        
        return moves
    }
    
    var winnerColor: Color? {
        if whiteScore >= Config.targetScore {
            return .white
        } else if blackScore >= Config.targetScore {
            return .black
        } else {
            return nil
        }
    }
    
    func isLaterThan(game: MonsGame) -> Bool {
        if turnNumber > game.turnNumber {
            return true
        } else if turnNumber == game.turnNumber {
            return playerPotionsCount < game.playerPotionsCount ||
            actionsUsedCount > game.actionsUsedCount ||
            manaMovesCount > game.manaMovesCount ||
            monsMovesCount > game.monsMovesCount ||
            board.faintedMonsLocations(color: activeColor.other).count > game.board.faintedMonsLocations(color: activeColor.other).count
        } else {
            return false
        }
    }
    
    var isFirstTurn: Bool { turnNumber == 1 }
    var playerPotionsCount: Int { activeColor == .white ? whitePotionsCount : blackPotionsCount }
    var playerCanMoveMon: Bool { monsMovesCount < Config.monsMovesPerTurn }
    var playerCanMoveMana: Bool { !isFirstTurn && manaMovesCount < Config.manaMovesPerTurn }
    var playerCanUseAction: Bool { !isFirstTurn && (playerPotionsCount > 0 || actionsUsedCount < Config.actionsPerTurn) }
    
    var protectedByOpponentsAngel: Set<Location> {
        if let location = board.findAwakeAngel(color: activeColor.other) {
            let protected = location.nearbyLocations
            return Set(protected)
        } else {
            return Set()
        }
    }
    
}
