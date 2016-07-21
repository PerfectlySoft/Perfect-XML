import XCTest
@testable import PerfectXML

class PerfectXMLTests: XCTestCase {
	
    func testDoc1() {
        let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b><c a=\"attr1\">HI</c><d/></b></a>\n"
		let doc = XMLDocument(fromSource: docSrc)
		let str = doc?.string(pretty: false)
		XCTAssert(str == docSrc, "\(str)")
    }

    static var allTests : [(String, (PerfectXMLTests) -> () throws -> Void)] {
        return [
            ("testDoc1", testDoc1),
        ]
    }
}
