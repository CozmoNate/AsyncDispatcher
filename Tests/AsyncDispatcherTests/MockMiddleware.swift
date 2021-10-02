//
//  Copyright © 2020 Natan Zalkin. All rights reserved.
//

import Foundation

@testable import AsyncDispatcher

class MockMiddleware: Middleware {
    
    var shouldExecute = true
    var lastExecutedDispatcher: Any?
    var lastExecutedAction: Any?
    var lastAskedAction: Any?
    var lastAskedStore: Any?
    
    func dispatcher<Dispatcher, Action>(_ dispatcher: Dispatcher, shouldExecute action: Action) -> Bool {
        lastAskedStore = dispatcher
        lastAskedAction = action
        return shouldExecute
    }
    
    func dispatcher<Dispatcher, Action>(_ dispatcher: Dispatcher, willExecute action: Action) {}
    
    func dispatcher<Dispatcher, Action>(_ dispatcher: Dispatcher, didExecute action: Action) {
        lastExecutedDispatcher = dispatcher
        lastExecutedAction = action
    }
}
