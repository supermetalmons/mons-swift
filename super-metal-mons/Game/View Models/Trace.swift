// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

struct Trace {
    
    enum Kind {
        case monMove
    }
    
    let from: Location
    let to: Location
    let kind: Kind
    
}
