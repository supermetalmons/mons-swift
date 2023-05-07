// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

// TODO: do not play audio from the game logic code

// TODO: refactor. do not add computed / helpers stuff to the base MonsGame implementaion — to keep it clean
extension MonsGame {
    // TODO: хочется понятную терминологию. и тут moves и там moves
    // TODO: вот непонятно, почему слева monStep, а справа monsMovesPerTurn
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
    
}

extension MonsGame {
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

extension MonsGame {
    
    enum Modifier {
        case selectPotion, selectBomb, cancel
    }
    
    enum Input: Equatable {
        case location(Location)
        case modifier(Modifier)
    }
    
    enum Output {
        case invalidInput
        case nextInputOptions([NextInput])
        case events([Event])
    }
    
    struct NextInput {
        
        enum Kind {
            case monMove, manaMove
            case mysticAction, demonAction, demonAdditionalStep, spiritTargetCapture, spiritTargetMove
            case selectConsumable, bombAttack
        }
        
        let input: Input
        let kind: Kind
        let actorMonItem: Item?
        
        init(input: Input, kind: Kind, actorMonItem: Item? = nil) {
            self.input = input
            self.kind = kind
            self.actorMonItem = actorMonItem
        }
        
    }
    
    enum Event {
        case monMove(item: Item, from: Location, to: Location)
        case manaMove(mana: Mana, from: Location, to: Location)
        case manaScored(mana: Mana, at: Location, pool: Color)
        case mysticAction(mystic: Mon, from: Location, to: Location)
        case demonAction(demon: Mon, from: Location, to: Location)
        case demonAdditionalStep(demon: Mon, from: Location, to: Location)
        case spiritTargetMove(item: Item, from: Location, to: Location)
        case pickupBomb(by: Mon, at: Location)
        case pickupPotion(by: Item, at: Location)
        case pickupMana(mana: Mana, by: Mon, at: Location)
        case monFainted(mon: Mon, from: Location, to: Location)
        case manaDropped(mana: Mana, at: Location)
        case supermanaBackToBase(from: Location, to: Location)
        case bombAttack(by: Mon, from: Location, to: Location)
        case monAwake(mon: Mon, at: Location)
        case bombExplosion(at: Location)
        case nextTurn(color: Color)
        case gameOver(winner: Color)
    }
    
    func processInput(_ input: [Input]) -> Output {
        guard !input.isEmpty,
              case let .location(startLocation) = input[0],
                let startItem = board.item(at: startLocation) else { return .invalidInput }
        
        let startSquare = board.square(at: startLocation)
        
        var nextInputOptions = [NextInput]()
        
        switch startItem {
        case .mon(let mon):
            guard mon.color == activeColor, !mon.isFainted else { return .invalidInput }
            
            if playerCanMoveMon {
                let moveLocations = startLocation.nearbyLocations.filter { location in
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
                
                nextInputOptions.append(contentsOf: moveLocations.map { NextInput(input: Input.location($0), kind: .monMove) })
            }
            
            if case .monBase = startSquare {
                // can't use action from the base
            } else if playerCanUseAction {
                var actionOptions = [NextInput]()
                switch mon.kind {
                case .angel, .drainer:
                    break
                case .mystic:
                    actionOptions = startLocation.reachableByMysticAction.compactMap { location -> NextInput? in
                        guard let item = board.item(at: location), !protectedByOpponentsAngel.contains(location) else { return nil }
                        
                        switch item {
                        case let .mon(targetMon), let .monWithMana(targetMon, _), let .monWithConsumable(targetMon, _):
                            if mon.color == targetMon.color || targetMon.isFainted {
                                return nil
                            }
                        case .mana, .consumable:
                            return nil
                        }
                        
                        return NextInput(input: .location(location), kind: .mysticAction)
                    }
                case .demon:
                    actionOptions = startLocation.reachableByDemonAction.compactMap { location -> NextInput? in
                        guard let item = board.item(at: location), !protectedByOpponentsAngel.contains(location) else { return nil }
                        let locationBetween = startLocation.locationBetween(another: location)
                        guard board.item(at: locationBetween) == nil else { return nil }
                        
                        switch item {
                        case .mon(let targetMon), let .monWithMana(targetMon, _), let .monWithConsumable(targetMon, _):
                            if mon.color == targetMon.color || targetMon.isFainted {
                                return nil
                            }
                        case .mana, .consumable:
                            return nil
                        }
                        
                        return NextInput(input: .location(location), kind: .demonAction)
                    }
                case .spirit:
                    actionOptions = startLocation.reachableBySpiritAction.compactMap { location -> NextInput? in
                        guard let item = board.item(at: location) else { return nil }
                        
                        switch item {
                        case .mon(let targetMon), let .monWithMana(targetMon, _), let .monWithConsumable(targetMon, _):
                            if targetMon.isFainted { return nil }
                        case .mana, .consumable:
                            break
                        }
                        
                        return NextInput(input: .location(location), kind: .spiritTargetCapture)
                    }
                }
                nextInputOptions.append(contentsOf: actionOptions)
            }
            
        case .mana(let mana):
            guard case let .regular(color) = mana, color == activeColor, playerCanMoveMana else { return .invalidInput }
            
            let manaMoveLocations = startLocation.nearbyLocations.filter { location in
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
            
            nextInputOptions.append(contentsOf: manaMoveLocations.map { NextInput(input: Input.location($0), kind: .manaMove) })
            
        case .monWithMana(let mon, let mana):
            guard mon.color == activeColor, playerCanMoveMon else { return .invalidInput }
            
            let moveLocations = startLocation.nearbyLocations.filter { location in
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
                case .supermanaBase:
                    return mana == .supermana
                case .monBase:
                    return false
                }
            }
            
            nextInputOptions.append(contentsOf: moveLocations.map { NextInput(input: Input.location($0), kind: .monMove) })
                        
        case .monWithConsumable(let mon, let consumable):
            guard mon.color == activeColor else { return .invalidInput }
            
            if playerCanMoveMon {
                let moveLocations = startLocation.nearbyLocations.filter { location in
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
                
                nextInputOptions.append(contentsOf: moveLocations.map { NextInput(input: Input.location($0), kind: .monMove) })
            }
            
            if case .bomb = consumable {
                let bombOptions = startLocation.reachableByBomb.compactMap { location -> NextInput? in
                    guard let item = board.item(at: location) else { return nil }
                    
                    switch item {
                    case let .mon(targetMon), let .monWithMana(targetMon, _), let .monWithConsumable(targetMon, _):
                        if mon.color == targetMon.color || targetMon.isFainted {
                            return nil
                        }
                    case .consumable, .mana:
                        return nil
                    }
                    
                    return NextInput(input: .location(location), kind: .bombAttack)
                }
                nextInputOptions.append(contentsOf: bombOptions)
            }
        case .consumable:
            return .invalidInput
        }
                
        guard input.count > 1 else {
            if nextInputOptions.isEmpty {
                return .invalidInput
            } else {
                return .nextInputOptions(nextInputOptions)
            }
        }
        
        let secondInput = input[1]
        guard case let .location(targetLocation) = secondInput else { return .invalidInput }
        guard let option = nextInputOptions.first(where: { $0.input == secondInput }) else { return .invalidInput }
        
        nextInputOptions = []
        var events = [Event]()
        let targetSquare = board.square(at: targetLocation)
        let targetItem = board.item(at: targetLocation)
        
        switch option.kind {
        case .monMove:
            guard let startMon = startItem.mon else { return .invalidInput }
            events.append(.monMove(item: startItem, from: startLocation, to: targetLocation))
            
            if let targetItem = targetItem {
                switch targetItem {
                case .mon, .monWithMana, .monWithConsumable:
                    return .invalidInput
                case .mana(let mana):
                    events.append(.pickupMana(mana: mana, by: startMon, at: targetLocation))
                case .consumable(let consumable):
                    switch consumable {
                    case .potion, .bomb:
                        return .invalidInput
                    case .bombOrPotion:
                        if startItem.consumable != nil || startItem.mana != nil {
                            events.append(.pickupPotion(by: startItem, at: targetLocation))
                        } else {
                            nextInputOptions = [
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
            case .manaPool(let color):
                if let manaInHand = startItem.mana {
                    events.append(.manaScored(mana: manaInHand, at: targetLocation, pool: color))
                }
            }
            
        case .manaMove:
            guard case let .mana(mana) = startItem else { return .invalidInput }
            events.append(.manaMove(mana: mana, from: startLocation, to: targetLocation))
            
            if let targetItem = targetItem {
                switch targetItem {
                case .mon(let mon):
                    events.append(.pickupMana(mana: mana, by: mon, at: targetLocation))
                case .mana, .consumable, .monWithMana, .monWithConsumable:
                    return .invalidInput
                }
            }
            
            switch targetSquare {
            case .manaBase, .consumableBase, .regular:
                break
            case .manaPool(let color):
                events.append(.manaScored(mana: mana, at: targetLocation, pool: color))
            case .monBase, .supermanaBase:
                return .invalidInput
            }
        case .mysticAction:
            guard let startMon = startItem.mon, let targetItem = targetItem else { return .invalidInput }
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
                    return .invalidInput
                case .bomb:
                    events.append(.bombExplosion(at: targetLocation))
                }
            case .consumable, .mana:
                return .invalidInput
            }
            
        case .demonAction:
            guard let startMon = startItem.mon, let targetItem = targetItem else { return .invalidInput }
            events.append(.demonAction(demon: startMon, from: startLocation, to: targetLocation))
            var requiresAdditionalStep = false
      
            switch targetItem {
            case .mana, .consumable:
                return .invalidInput
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
                    return .invalidInput
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
                let additionalStepLocations = targetLocation.nearbyLocations.filter { location in
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
                
                nextInputOptions.append(contentsOf: additionalStepLocations.map { NextInput(input: Input.location($0), kind: .demonAdditionalStep) })
            }
            
        case .spiritTargetCapture:
            guard let targetItem = targetItem else { return .invalidInput }
            let targetMon = targetItem.mon
            let targetMana = targetItem.mana
            
            let spiritMoveLocations = targetLocation.nearbyLocations.filter { location in
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
            
            nextInputOptions.append(contentsOf: spiritMoveLocations.map { NextInput(input: Input.location($0), kind: .spiritTargetMove) })
            
        case .bombAttack:
            guard let startMon = startItem.mon, let targetItem = targetItem else { return .invalidInput }
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
                    return .invalidInput
                case .bomb:
                    events.append(.bombExplosion(at: targetLocation))
                }
            case .mana, .consumable:
                return .invalidInput
            }

        case .spiritTargetMove, .demonAdditionalStep, .selectConsumable:
            return .invalidInput
        }
        
        guard input.count > 2 else {
            if !nextInputOptions.isEmpty {
                return .nextInputOptions(nextInputOptions)
            } else if !events.isEmpty {
                return .events(apply(events: events))
            } else {
                return .invalidInput
            }
        }
        
        let thirdInput = input[2]
        guard let option = nextInputOptions.first(where: { $0.input == thirdInput }) else { return .invalidInput }
        nextInputOptions = []
                
        switch option.kind {
        case .monMove, .manaMove, .mysticAction, .demonAction, .spiritTargetCapture, .bombAttack:
            return .invalidInput
        case .spiritTargetMove:
            guard case let .location(destinationLocation) = thirdInput, let targetItem = targetItem else { return .invalidInput }
            let destinationItem = board.item(at: destinationLocation)
            let destinationSquare = board.square(at: destinationLocation)
            
            events.append(.spiritTargetMove(item: targetItem, from: targetLocation, to: destinationLocation))
            
            if let destinationItem = destinationItem {
                
                switch targetItem {
                case .mon(let travellingMon):
                    switch destinationItem {
                    case .mon, .monWithMana, .monWithConsumable:
                        return .invalidInput
                    case .mana(let destinationMana):
                        events.append(.pickupMana(mana: destinationMana, by: travellingMon, at: destinationLocation))
                    case .consumable(let destinationConsumable):
                        switch destinationConsumable {
                        case .potion, .bomb:
                            return .invalidInput
                        case .bombOrPotion:
                            nextInputOptions = [
                                NextInput(input: Input.modifier(.selectBomb), kind: .selectConsumable, actorMonItem: targetItem),
                                NextInput(input: Input.modifier(.selectPotion), kind: .selectConsumable, actorMonItem: targetItem)
                            ]
                        }
                    }
                    
                case .mana(let travellingMana):
                    switch destinationItem {
                    case .mana, .monWithMana, .monWithConsumable, .consumable:
                        return .invalidInput
                    case .mon(let destinationMon):
                        events.append(.pickupMana(mana: travellingMana, by: destinationMon, at: destinationLocation))
                    }
                    
                case .monWithMana:
                    switch destinationItem {
                    case .mon, .mana, .monWithMana, .monWithConsumable:
                        return .invalidInput
                    case .consumable(let destinationConsumable):
                        switch destinationConsumable {
                        case .potion, .bomb:
                            return .invalidInput
                        case .bombOrPotion:
                            events.append(.pickupPotion(by: targetItem, at: destinationLocation))
                        }
                    }
                    
                case .monWithConsumable:
                    switch destinationItem {
                    case .mon, .mana, .monWithMana, .monWithConsumable:
                        return .invalidInput
                    case .consumable(let destinationConsumable):
                        switch destinationConsumable {
                        case .potion, .bomb:
                            return .invalidInput
                        case .bombOrPotion:
                            events.append(.pickupPotion(by: targetItem, at: destinationLocation))
                        }
                    }
                    
                case .consumable(let travellingConsumable):
                    switch destinationItem {
                    case .mana, .consumable:
                        return .invalidInput
                    case .mon:
                        nextInputOptions = [
                            NextInput(input: Input.modifier(.selectBomb), kind: .selectConsumable, actorMonItem: destinationItem),
                            NextInput(input: Input.modifier(.selectPotion), kind: .selectConsumable, actorMonItem: destinationItem)
                        ]
                    case .monWithMana, .monWithConsumable:
                        switch travellingConsumable {
                        case .potion, .bomb:
                            return .invalidInput
                        case .bombOrPotion:
                            events.append(.pickupPotion(by: destinationItem, at: destinationLocation))
                        }
                    }
                }
                
            }
            
            if case .manaPool(let color) = destinationSquare, let mana = targetItem.mana {
                events.append(.manaScored(mana: mana, at: destinationLocation, pool: color))
            }
            
        case .demonAdditionalStep:
            guard case let .location(destinationLocation) = thirdInput, let demon = startItem.mon else { return .invalidInput }
            events.append(.demonAdditionalStep(demon: demon, from: targetLocation, to: destinationLocation))
            
            if let item = board.item(at: destinationLocation), case .consumable(let consumable) = item {
                switch consumable {
                case .potion, .bomb:
                    return .invalidInput
                case .bombOrPotion:
                    nextInputOptions = [
                        NextInput(input: Input.modifier(.selectBomb), kind: .selectConsumable, actorMonItem: startItem),
                        NextInput(input: Input.modifier(.selectPotion), kind: .selectConsumable, actorMonItem: startItem)
                    ]
                }
            }
            
        case .selectConsumable:
            guard case let .modifier(modifier) = thirdInput, let mon = startItem.mon else { return .invalidInput }
            switch modifier {
            case .selectBomb:
                events.append(.pickupBomb(by: mon, at: targetLocation))
            case .selectPotion:
                events.append(.pickupPotion(by: startItem, at: targetLocation))
            case .cancel:
                return .invalidInput
            }
        }
        
        guard input.count > 3 else {
            if !nextInputOptions.isEmpty {
                return .nextInputOptions(nextInputOptions)
            } else if !events.isEmpty {
                return .events(apply(events: events))
            } else {
                return .invalidInput
            }
        }
        
        let forthInput = input[3]
        
        guard case let .modifier(modifier) = forthInput else { return .invalidInput }
        guard nextInputOptions.contains(where: { $0.input == forthInput }),
              case let .location(destinationLocation) = thirdInput,
              let actorMonItem = nextInputOptions.last?.actorMonItem, let actorMon = actorMonItem.mon else { return .invalidInput }
        
        switch modifier {
        case .selectBomb:
            events.append(.pickupBomb(by: actorMon, at: destinationLocation))
        case .selectPotion:
            events.append(.pickupPotion(by: actorMonItem, at: destinationLocation))
        case .cancel:
            return .invalidInput
        }
        
        return .events(apply(events: events))
    }
    
    private func apply(events: [Event]) -> [Event] {
        
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
            case .manaScored(let mana, let at, let pool):
                switch pool {
                case .black:
                    blackScore += mana.score
                case .white:
                    whiteScore += mana.score
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
    
}

class MonsGame {
    
    let board: Board
        
    private(set) var whiteScore: Int
    private(set) var blackScore: Int
    private(set) var activeColor: Color
    
    private(set) var actionsUsedCount: Int
    private(set) var manaMovesCount: Int
    private(set) var monsMovesCount: Int
    
    private(set) var whitePotionsCount: Int
    private(set) var blackPotionsCount: Int
    
    private(set) var turnNumber: Int
    
    init() {
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
   
}
