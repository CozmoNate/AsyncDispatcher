//
//  Copyright © 2020 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble

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

class DispatcherTests: QuickSpec {
    override func spec() {
        describe("Dispatcher") {
            var subject: MockDispatcher!
            
            beforeEach {
                subject = MockDispatcher()
            }
            
            it("can execute actions and appropriately change state") {
                subject.execute(MockDispatcher.Change(value: "sync test"))
                subject.execute(MockDispatcher.AsyncChange(value: "async test"))
                
                expect(subject.value).toEventually(equal("sync test"))
                expect(subject.value).toEventually(equal("async test"))
            }
            
            it("can dispatch actions and appropriately change state") {
                expect(subject.value).to(equal("initial"))
                expect(subject.isDispatching).to(beFalse())
                expect(subject.pipeline.isEmpty).to(beTrue())
                
                subject.dispatch(MockDispatcher.AsyncChange(value: "async test"))
                subject.dispatch(MockDispatcher.AsyncChange(value: "async test after"))
                subject.dispatch(MockDispatcher.Change(value: "async test finish"))
                
                expect(subject.isDispatching).toEventually(beTrue())
                expect(subject.pipeline.count).toEventually(equal(2))
                expect(subject.value).toEventually(equal("async test finish"))
            }
            
            it("can await for async action to finish dispatching") {
                waitUntil { done in
                    Task { [subject] in
                        await subject!.dispatch(MockDispatcher.AsyncChange(value: "await dispatch test"))
                        expect(subject!.value).to(equal("await dispatch test"))
                        done()
                    }
                }
            }
            
            it("can await for conventional action to finish executing") {
                waitUntil { done in
                    subject!.dispatch(MockDispatcher.AsyncChange(value: "dispatch completion test")) {
                        expect(subject!.value).to(equal("dispatch completion test"))
                        done()
                    }
                }
            }
        }
    }
}
