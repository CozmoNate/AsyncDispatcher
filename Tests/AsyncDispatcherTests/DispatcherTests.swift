//
//  Copyright © 2020 Natan Zalkin. All rights reserved.
//

import XCTest

@testable import AsyncDispatcher

extension Pipeline {
    
    var count: Int {
        guard var item = head else {
            return 0
        }
        var count = 1
        while let next = item.next {
            count += 1
            item = next
        }
        return count
    }
    
}

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
        XCTAssertEqual(subject.value, "sync test")
        await subject.execute(MockDispatcher.AsyncChange(value: "async test"))
        XCTAssertEqual(subject.value, "async test")
    }
    
    @MainActor func testDispatcherActionScheduledExecution() async {
        XCTAssertEqual(subject.value, "initial")
        
        Task { await self.subject.dispatch(MockDispatcher.AsyncChange(value: "async test")) }
        Task { await self.subject.dispatch(MockDispatcher.AsyncChange(value: "async test after")) }
        Task { await self.subject.dispatch(MockDispatcher.Change(value: "async test finish")) }

        repeat {
            await Task.yield()
        } while await subject.isDispatching
        
        XCTAssertEqual(subject.value, "async test finish")
    }
}
