//
//  Copyright © 2020 Natan Zalkin. All rights reserved.
//

import XCTest

@testable import AsyncDispatcher

class MiddlewareTests: XCTestCase {
    
    var dispatcher: MockDispatcher!
    var subject: MockMiddleware!
    
    override func setUp() async throws {
        try await super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        dispatcher = MockDispatcher()
        subject = (await dispatcher.middlewares[0]) as? MockMiddleware
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        super.tearDown()
    }
    
    func testMiddlewareCanPreventActionExecution() async {
        subject.shouldExecute = false
        
        await dispatcher.dispatch(MockDispatcher.Change(value: "test"))
        await dispatcher.waitUntilFinished()
        
        XCTAssert(subject.lastAskedAction is MockDispatcher.Change)
        XCTAssertNotNil(subject.lastAskedAction)
        XCTAssertNil(subject.lastExecutedAction)
    }
    
    func testMiddlewareTrackActionExecution() async {
        subject.shouldExecute = true
        
        await dispatcher.dispatch(MockDispatcher.Change(value: "test"))
        await dispatcher.waitUntilFinished()
        
        XCTAssert(subject.lastAskedAction is MockDispatcher.Change)
        XCTAssertNotNil(subject.lastAskedAction)
        XCTAssert(subject.lastExecutedAction is MockDispatcher.Change)
        XCTAssertNotNil(subject.lastExecutedAction)
    }
}
