//
//  Copyright (c) Levin Li. All rights reserved.
//  Licensed under the MIT License.
//

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MWRequestTests.allTests),
    ]
}
#endif
