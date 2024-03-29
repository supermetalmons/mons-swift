// ∅ 2024 super-metal-mons

import Foundation

struct Keychain {
    
    static let shared = Keychain()
    private init() {}
    
    enum KeychainError: Error {
        case unknown
    }
    
    private enum ItemKey {
        case denverCode
        
        private static let commonPrefix = "lol.ivan.super-metal-mons."

        var stringValue: String {
            return ItemKey.commonPrefix + "claim.24.denver"
        }
        
    }
    
    var denverCode: String? {
        if let data = get(key: .denverCode), let denverCode = String(data: data, encoding: .utf8) {
            return denverCode
        } else {
            return nil
        }
    }
    
    // TODO: separate values for separate drops
    
    func save(denverCode: String) {
        guard let data = denverCode.data(using: .utf8) else { return }
        save(data: data, key: .denverCode)
    }

    // MARK: - Private
    
    private func update(data: Data, key: ItemKey) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key.stringValue]
        let attributes: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status == errSecSuccess else { throw KeychainError.unknown }
    }
    
    private func save(data: Data, key: ItemKey) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key.stringValue,
                                    kSecValueData as String: data]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func allStoredItemsKeys() -> [String] {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecReturnData as String: false,
                                    kSecReturnAttributes as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitAll]
        var items: CFTypeRef?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &items)
        if status == noErr, let items = items as? [[String: Any]], !items.isEmpty {
            let sorted = items.sorted(by: { ($0[kSecAttrCreationDate as String] as? Date ?? Date()) < ($1[kSecAttrCreationDate as String] as? Date ?? Date()) })
            return sorted.compactMap { $0[kSecAttrAccount as String] as? String }
        } else {
            return []
        }
    }
    
    private func removeData(forKey key: ItemKey) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                     kSecAttrAccount as String: key.stringValue]
        SecItemDelete(query as CFDictionary)
    }
    
    private func get(key: ItemKey) -> Data? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key.stringValue,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &item)
        if status == noErr, let data = item as? Data {
            return data
        } else {
            return nil
        }
    }
    
}
