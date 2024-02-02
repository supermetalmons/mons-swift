// ∅ 2024 super-metal-mons

import Foundation

struct TestCase: Codable, Hashable {
    let fenBefore: String
    let input: [Input]
    let output: Output
    let fenAfter: String
}
