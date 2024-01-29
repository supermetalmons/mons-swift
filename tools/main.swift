// ∅ 2024 super-metal-mons

import Foundation

struct TestCase: Codable {
    let fenBefore: String
    let input: [Input]
    let output: Output
    let fenAfter: String
}

var count = 0

func validate(data: Data) {
    let testCase = try! JSONDecoder().decode(TestCase.self, from: data)
    let game = MonsGame(fen: testCase.fenBefore)!
    let result = game.processInput(testCase.input, doNotApplyEvents: false, oneOptionEnough: false)
    let outputSame = result == testCase.output
    let fenSame = game.fen == testCase.fenAfter
    if outputSame && fenSame {
        count += 1
        print("✅ ok \(count)")
    } else {
        if !outputSame {
            print("🛑 output", result)
            print("💾 output", testCase.output)
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
    validate(data: data)
}

print("all done")
