//
//  Copyright © 2020 Natan Zalkin. All rights reserved.
//

import XCTest

@testable import AsyncDispatcher

class DispatcherTests: XCTestCase {
    
    var subject: MockDispatcher!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        subject = MockDispatcher()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        super.tearDown()
    }
    
    @MainActor func testDispatcherActionImmediateExecution() async {
        await subject.execute(MockDispatcher.Change(value: "sync test"))
        XCTAssertEqual(subject.values, ["initial", "sync test"])
        await subject.execute(MockDispatcher.AsyncChange(value: "async test"))
        XCTAssertEqual(subject.values, ["initial", "sync test", "async test"])
    }
    
    @MainActor func testDispatcherActionScheduledExecution() async {
        XCTAssertEqual(subject.values, ["initial"])
        
        let isDispatching = await subject.isDispatching
        XCTAssertFalse(isDispatching, "dispatcher should be free")
        
        await subject.dispatch(MockDispatcher.AsyncChange(value: "async test"))
        await subject.dispatch(MockDispatcher.AsyncChange(value: "async test after"))
        await subject.dispatch(MockDispatcher.Change(value: "async test finish"))
        
        let tick = await subject.waitUntilFinished()
        
        XCTAssertGreaterThan(tick, 1)
        XCTAssertEqual(subject.values, ["initial", "async test", "async test after", "async test finish"])
    }
    
    @MainActor func testInactiveDispatcher() async {
        XCTAssertEqual(subject.values, ["initial"])

        await subject.deactivate()

        var isBusy = await subject.isDispatching
        var isEmpty = await subject.pipeline.isEmpty
        
        XCTAssertFalse(isBusy, "dispatcher should NOT be busy")
        XCTAssertTrue(isEmpty, "pipeline should be empty")
        
        await subject.dispatch(MockDispatcher.AsyncChange(value: "async test"))
        await subject.dispatch(MockDispatcher.AsyncChange(value: "async test after"))
        await subject.dispatch(MockDispatcher.Change(value: "async test finish"))

        isBusy = await subject.isDispatching
        isEmpty = await subject.pipeline.isEmpty
        
        XCTAssertFalse(isBusy, "dispatcher should NOT busy")
        XCTAssertFalse(isEmpty, "pipeline should NOT be empty")

        await subject.activate() // This should execute all the actions

        let tick = await subject.waitUntilFinished()
        
        isBusy = await subject.isDispatching
        isEmpty = await subject.pipeline.isEmpty
        
        XCTAssertGreaterThan(tick, 1)
        XCTAssertFalse(isBusy, "dispatched should execute all the actions upon activation")
        XCTAssertTrue(isEmpty, "pipeline should be empty now")
        XCTAssertEqual(subject.values, ["initial", "async test", "async test after", "async test finish"])
    }
}
