import XCTest
@testable import PerfectXML

class PerfectXMLTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(PerfectXML().text, "Hello, World!")
    }


    static var allTests : [(String, (PerfectXMLTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
