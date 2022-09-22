//
//  Copyright © 2020 Natan Zalkin. All rights reserved.
//

import Foundation

@testable import AsyncDispatcher

@globalActor actor MockDispatcher: Dispatcher, GlobalActor {
    
    static var shared = MockDispatcher()

    @MainActor private(set) var value = "initial"
    @MainActor private(set) var number = 0
    
    var pipeline = Pipeline()
    var middlewares = [MockMiddleware()] as Array<Middleware>
    var isDispatching = false
}

extension MockDispatcher {
    
    struct Change: Action {
        let value: String
        
        @MainActor func execute(with store: MockDispatcher) async {
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
        
        @MainActor func execute(with store: MockDispatcher) async {
            store.number = number
        }
    }
}
