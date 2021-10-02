//
//  Copyright © 2020 Natan Zalkin. All rights reserved.
//

import Foundation

@testable import AsyncDispatcher

class MockDispatcher: Dispatcher {
    
    struct Change: Action {
        let value: String
        
        func execute(with store: MockDispatcher) async {
            store.value = value
        }
    }
    
    struct AsyncChange: Action {
        let value: String
        
        func execute(with store: MockDispatcher) async {
            return await withCheckedContinuation { continuation in
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(250)) {
                    DispatchQueue.main.async {
                        store.value = value
                        continuation.resume()
                    }
                }
            }
            
        }
    }
    
    struct Update: Action {
        let number: Int
        
        func execute(with store: MockDispatcher) async {
            store.number = number
        }
    }
    
    private(set) var value = "initial"
    private(set) var number = 0
    
    var pipeline = Pipeline()
    var middlewares = [MockMiddleware()] as Array<Middleware>
    var isDispatching = false
}
