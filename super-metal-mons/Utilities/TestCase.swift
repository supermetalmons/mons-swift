// ∅ 2024 super-metal-mons

import Foundation

struct TestCase: Codable, Hashable, FenRepresentable {

    let fenBefore: String
    let input: [Input]
    let output: Output
    let fenAfter: String
    
    var fen: String {
        let components = [fenBefore, fenAfter, input.fen, output.fen]
        return String(components.joined(separator: "\n"))
    }
    
    init?(fen: String) {
        // TODO: implement
        return nil
    }
    
}
