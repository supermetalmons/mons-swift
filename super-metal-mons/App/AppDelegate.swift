// ∅ 2024 super-metal-mons

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Firebase.setup()
        Audio.shared.prepare()
        return true
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return true
    }
    
#if !targetEnvironment(macCatalyst)
    
    private func uploadClaimCodes(dropId: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) { [weak self] in
            if let userId = Firebase.userId, let codes = self?.loadClaimCodes() {
                print(userId)
                Firebase.createCodes(codes: codes, dropId: dropId)
            } else {
                print("🛑")
            }
        }
    }
    
    private func loadClaimCodes() -> [String] {
        guard let path = Bundle.main.path(forResource: "links", ofType: "csv"),
              let data = try? String(contentsOfFile: path, encoding: .utf8) else { return [] }
        let rows = data.components(separatedBy: "\n")
        var claimCodes: [String] = []
        for (index, row) in rows.enumerated() {
            if index == 0 || row.isEmpty { continue }
            let columns = row.components(separatedBy: ",")
            if columns.count > 4 {
                let claimCode = columns[4]
                claimCodes.append(claimCode)
            }
        }
        return claimCodes
    }
    
#endif
    
}
