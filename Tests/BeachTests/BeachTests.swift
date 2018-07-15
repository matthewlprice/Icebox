import XCTest
@testable import Beach

final class BeachTests: XCTestCase {
    
    func testExample() throws {
        let runner = IceRunner(sandbox: .simple)
        
        let result = runner.run(arguments: ["file.txt"], timeout: 4)
        result.assertSuccess()
        XCTAssertEqual(result.stdout, "hello\n")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

class IceConfig: RunnerConfig {
    
    enum Sandboxes: String {
        case simple
        case lib
    }
    
    static let executable = "/bin/cat"
    
    static func configure(process: Process) {
        var env = ProcessInfo.processInfo.environment
        env["ICE_GLOBAL_ROOT"] = "global"
        process.environment = env
    }
    
}

typealias IceRunner = Runner<IceConfig>

//func run() {
//
//}
