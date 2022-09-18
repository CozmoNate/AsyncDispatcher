//
//  Copyright © 2020 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble

@testable import AsyncDispatcher

class MiddlewareTests: QuickSpec {
    override func spec() {
        describe("Middleware") {
            
            var store: MockDispatcher!
            var subject: MockMiddleware!
            
            beforeEach {
                store = MockDispatcher()
                subject = store.middlewares[0] as? MockMiddleware
            }
            
            context("when dispatched an action") {
                
                beforeEach {
                    subject.shouldExecute = false
                    Task { [store] in
                        await store?.dispatch(MockDispatcher.Change(value: "test"))
                    }
                }
            
                it("can prevent the action for being executed") {
                    expect(subject.lastAskedAction).toEventually(beAKindOf(MockDispatcher.Change.self))
                    expect(subject.lastExecutedAction).toEventually(beNil())
                }
            }
        }
    }
}
