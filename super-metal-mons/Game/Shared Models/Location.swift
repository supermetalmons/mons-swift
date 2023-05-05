// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

struct Location: Equatable, Hashable {
    
    private static let validRange = 0..<Config.boardSize
    
    let i: Int
    let j: Int
    
    init(_ i: Int, _ j: Int) {
        self.i = i
        self.j = j
    }
    
    var nearbyLocations: [Location] {
        return nearbyLocations(distance: 1)
    }
    
    var reachableByBomb: [Location] {
        return nearbyLocations(distance: 3)
    }
    
    var reachableByMysticAction: [Location] {
        let locations = [(i - 2, j - 2), (i + 2, j + 2), (i - 2, j + 2), (i + 2, j - 2)].compactMap { a, b -> Location? in
            if Location.validRange ~= a && Location.validRange ~= b {
                return Location(a, b)
            } else {
                return nil
            }
        }
        
        return locations
    }
    
    var reachableByDemonAction: [Location] {
        let locations = [(i - 2, j), (i + 2, j), (i, j + 2), (i, j - 2)].compactMap { a, b -> Location? in
            if Location.validRange ~= a && Location.validRange ~= b {
                return Location(a, b)
            } else {
                return nil
            }
        }
        
        return locations
    }
    
    var reachableBySpiritAction: [Location] {
        var locations = [Location]()
        for x in -2...2 {
            for y in -2...2 where max(abs(x), abs(y)) == 2 {
                let a = i + x
                let b = j + y
                if Location.validRange ~= a && Location.validRange ~= b {
                    locations.append(Location(a, b))
                }
            }
        }
        
        return locations
    }
    
    func locationBetween(another: Location) -> Location {
        return Location((i + another.i) / 2, (j + another.j) / 2)
    }
    
    private func nearbyLocations(distance: Int) -> [Location] {
        var locations = [Location]()
        for x in (i - distance)...(i + distance) {
            for y in (j - distance)...(j + distance) {
                if Location.validRange ~= x && Location.validRange ~= y, x != i || y != j {
                    locations.append(Location(x, y))
                }
            }
        }
        return locations
    }
            
}
