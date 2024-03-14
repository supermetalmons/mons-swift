// ∅ 2024 super-metal-mons

import Foundation

var count = 0

func validate(data: Data) {
    let testCase = try! JSONDecoder().decode(TestCase.self, from: data)
    let game = MonsGame(fen: testCase.fenBefore)!
    
    let recreatedInput = Array<Input>(fen: testCase.inputFen)
    let recreatedOutput = Output(fen: testCase.outputFen)
    
    let result = game.processInput(recreatedInput!, doNotApplyEvents: false, oneOptionEnough: false)
    
    let outputSame = result == recreatedOutput
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
    validate(data: data)
}

print("all done")
