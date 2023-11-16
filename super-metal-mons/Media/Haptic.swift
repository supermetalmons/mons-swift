// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

enum Haptic {
    
    case success, error, warning, selectionChanged
    
    static func generate(_ haptic: Haptic) {
        switch haptic {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .selectionChanged:
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
    
}
