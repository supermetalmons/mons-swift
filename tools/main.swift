// ∅ 2024 super-metal-mons

import Foundation

struct TestCase: Codable {
    
    let fenBefore: String
    let input: [Input]
    let output: Output
    let fenAfter: String
    
}

// Example function to be tested with JSON data

var count = 0

func yourFunction(jsonData: Data) {
    
    let testCase = try! JSONDecoder().decode(TestCase.self, from: jsonData)
    
    let game = MonsGame(fen: testCase.fenBefore)!
    let result = game.processInput(testCase.input, doNotApplyEvents: false)
    
    let outputSame = result == testCase.output
    let fenSame = game.fen == testCase.fenAfter
    
    if outputSame && fenSame {
        count += 1
//        print("✅ ok \(count)")
    } else {
//        print("gg", testCase)
        
        if !outputSame {
            print("🛑 output", result)
            print("💾 output", testCase.output)
            print(testCase.fenBefore)
        }
        
        if !fenSame {
            print("🛑 fen", game.fen)
            print("💾 fen", testCase.fenAfter)
        }
        
//        assert(false)
    }
    
    // Your implementation here
    // For example, parsing the JSON and performing some operation
}

// Main function of the command line tool
func main() {
    let jsonDirectory = FileManager.default.currentDirectoryPath + "/tools/test-data"

    do {
        let jsonFiles = try FileManager.default.contentsOfDirectory(atPath: jsonDirectory)
        for fileName in jsonFiles {
            if fileName.hasPrefix(".") { continue }
            let filePath = jsonDirectory + "/" + fileName
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            yourFunction(jsonData: data)
        }
    } catch {
        print("Error: \(error)")
    }
    
    print("all done")
}

main()
