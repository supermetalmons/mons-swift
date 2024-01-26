// ∅ 2024 super-metal-mons

import Foundation

extension Encodable {
    
    private var data: Data? {
        return try? JSONEncoder().encode(self)
    }

    var dict: [String: Any] {
        guard let data = self.data else { return [:] }
        let json = (try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)) as? [String: Any]
        return json ?? [:]
    }
    
}

extension Decodable {
    
    init(dict: Any) throws {
        let data = try JSONSerialization.data(withJSONObject: dict, options: .fragmentsAllowed)
        let decoder = JSONDecoder()
        self = try decoder.decode(Self.self, from: data)
    }
    
}
