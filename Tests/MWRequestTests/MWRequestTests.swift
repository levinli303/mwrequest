//
//  Copyright (c) Levin Li. All rights reserved.
//  Licensed under the MIT License.
//

import XCTest
@testable import MWRequest

@available(iOS 15.0, macOS 12.0, *)
final class MWRequestTests: XCTestCase {
    @available(iOS 15.0, macOS 12.0, *)
    func testAsyncGet() async {
        do {
            let data = try await AsyncDataRequestHandler.get(url: "https://baidu.com")
            XCTAssertNotEqual(data.count, 0)
        }
        catch {
            XCTFail()
        }
    }

    static var allTests = [
        ("testAsyncGet", testAsyncGet),
    ]
}
