// ∅ 2024 super-metal-mons

import Foundation

var count = 0

func rewrite(data: Data) {
    let testCase = try! JSONDecoder().decode(TestCase.self, from: data)
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    
    let newData = try! encoder.encode(testCase)
    let name = String(newData.fnv1aHash())
    
    let newDataDirectory = FileManager.default.currentDirectoryPath + "/tools/tuned/"
    let newFilePath = newDataDirectory + name
    
    if !FileManager.default.fileExists(atPath: newFilePath) {
        FileManager.default.createFile(atPath: newFilePath, contents: newData)
    }
}

func validate(data: Data) {
    let testCase = try! JSONDecoder().decode(TestCase.self, from: data)
    let game = MonsGame(fen: testCase.fenBefore)!
    
    let recreatedInput = Array<Input>(fen: testCase.inputFen)
    let recreatedOutput = Output(fen: testCase.outputFen)
    
    let result = game.processInput(recreatedInput!, doNotApplyEvents: false, oneOptionEnough: false)
    
    let outputSame = result.fen == testCase.outputFen
    let fenSame = game.fen == testCase.fenAfter
    if outputSame && fenSame {
        count += 1
        print("✅ ok \(count)")
    } else {
        if !outputSame {
            print("🛑 output", result)
            print("💾 output", recreatedOutput!)
        }
        if !fenSame {
            print("🛑 fen", game.fen)
            print("💾 fen", testCase.fenAfter)
        }
        assert(false)
    }
}

let testDataDirectory = FileManager.default.currentDirectoryPath + "/tools/test-data"
let files = try! FileManager.default.contentsOfDirectory(atPath: testDataDirectory)

for name in files {
    if name.hasPrefix(".") { continue }
    let filePath = testDataDirectory + "/" + name
    let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
    
    rewrite(data: data)
    validate(data: data)
}

print("all done")

extension Data {
    
    func fnv1aHash() -> UInt64 {
        let prime: UInt64 = 1099511628211
        var hash: UInt64 = 14695981039346656037
        forEach { byte in
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return hash
    }
    
}
