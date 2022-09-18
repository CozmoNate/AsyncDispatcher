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
            
            it("can execute actions immediately and appropriately change state") {
                Task { [subject] in
                    await subject?.execute(MockDispatcher.Change(value: "sync test"))
                }
                Task { [subject] in
                    await subject?.execute(MockDispatcher.AsyncChange(value: "async test"))
                }
                
                expect(subject.value).toEventually(equal("sync test"))
                expect(subject.value).toEventually(equal("async test"))
            }
            
            it("can dispatch actions and appropriately change state") {
                expect(subject.value).to(equal("initial"))
                expect(subject.isDispatching).to(beFalse())
                expect(subject.pipeline.isEmpty).to(beTrue())

                Task { [subject] in
                    await subject?.dispatch(MockDispatcher.AsyncChange(value: "async test"))
                }
                Task { [subject] in
                    await subject?.dispatch(MockDispatcher.AsyncChange(value: "async test after"))
                }
                Task { [subject] in
                    await subject?.dispatch(MockDispatcher.Change(value: "async test finish"))
                }

                expect(subject.isDispatching).toEventually(beTrue())
                expect(subject.pipeline.count).toEventually(equal(2))
                expect(subject.value).toEventually(equal("async test finish"))
            }
        }
    }
}
