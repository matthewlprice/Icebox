import XCTest
@testable import Beach

final class BeachTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Beach().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
