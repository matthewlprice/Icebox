import XCTest
@testable import Icebox

final class IceboxTests: XCTestCase {
    
    func testExample() throws {
        let runner = IceSandbox(template: .simple)
        
        let result = runner.run(arguments: ["file.txt"], timeout: 4)
        XCTAssertEqual(result.exitStatus, 0)
        XCTAssertEqual(result.stdout, "hello\n")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

class IceConfig: SandboxConfig {
    
    enum Templates: String {
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

typealias IceSandbox = Sandbox<IceConfig>

//func run() {
//
//}
