//
//  Copyright © 2020 Natan Zalkin. All rights reserved.
//

import Foundation

@testable import AsyncDispatcher

actor MockDispatcher: Dispatcher {
    
    static var shared = MockDispatcher()

    @MainActor private(set) var values = ["initial"]
    
    var pipeline = Pipeline()
    var middlewares = [MockMiddleware()] as Array<Middleware>
    var isActive = true
    var isDispatching = false
    
    @discardableResult func waitUntilFinished() async -> Int {
        var ticks = 0
        repeat {
            await Task.yield()
            ticks += 1
        } while isDispatching
        return ticks
    }
}

extension MockDispatcher {
    
    struct Change: Action {
        let value: String
        
        @MainActor func execute(with store: MockDispatcher) async {
            store.values.append(value) 
        }
    }
    
    struct AsyncChange: Action {
        let value: String
        
        @MainActor func execute(with store: MockDispatcher) async {
            try! await Task<Never, Never>.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
            store.values.append(value)
        }
    }
}
