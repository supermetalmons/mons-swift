// Copyright © 2023 super metal mons. All rights reserved.

import Foundation

// TODO: do not pass index tuples, instead use locations everywhere
struct Location: Equatable, Hashable {
    let i: Int
    let j: Int
    
    init(_ i: Int, _ j: Int) {
        self.i = i
        self.j = j
    }
    
    // TODO: DRY
    private static let monsBases: Set<Location> = {
        let coordinates = [(10, 5), (0, 5), (10, 4), (0, 6), (10, 6), (0, 4), (10, 3), (0, 7), (10, 7), (0, 3)]
        return Set(coordinates.map { Location($0.0, $0.1) })
    }()
    
    static func isMonsBase(_ i: Int, _ j: Int) -> Bool {
        return monsBases.contains(Location(i, j))
    }
    
    static func basedMon(_ i: Int, _ j: Int) -> Mon? {
        let color: Color
        switch i {
        case 0: color = .black
        case 10: color = .white // TODO: DRY
        default: return nil
        }
        
        switch (i, j) {
        case (10, 5), (0, 5): return Mon(kind: .drainer, color: color)
        case (10, 4), (0, 6): return Mon(kind: .angel, color: color)
        case (10, 6), (0, 4): return Mon(kind: .spirit, color: color)
        case (10, 3), (0, 7): return Mon(kind: .demon, color: color)
        case (10, 7), (0, 3): return Mon(kind: .mystic, color: color)
        default: return nil
        }
    }
    
    static func isSuperManaBase(_ i: Int, _ j: Int) -> Bool {
        // TODO: DRY
        return i == 5 && j == 5
    }
    
}
