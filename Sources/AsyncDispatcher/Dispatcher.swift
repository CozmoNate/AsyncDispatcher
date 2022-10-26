/*
 * Copyright (c) 2021 Natan Zalkin
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */

import Foundation
import Collections

/// Dispatcher is an object allowing to dispatch actions and provides infrastructure for actions to perform their job
public protocol Dispatcher: Actor {
    
    typealias Pipeline = Deque<() async -> Void>
    
    /// The queue of postponed actions
    var pipeline: Pipeline { get set }
    
    /// The list of objects that are conforming to Middleware protocol and receive events when the action is executed
    var middlewares: [Middleware] { get set }
    
    /// The flag indicating that an action is allowed to be executed
    var isActive: Bool { get set }
    
    /// The flag indicating that an action is being dispatched right now
    var isDispatching: Bool { get set }
}

public extension Dispatcher {
    
    /// Activates dispatcher and starts executing postponed actions.
    func activate() {
        isActive = true
        if !isDispatching {
            isDispatching = true
            Task {
                await flush()
            }
        }
    }
    
    /// Deactivates dispatcher. All new actions dispatched will be postponed and put into pipeline while dispatcher is inactive.
    /// Action which being executed at the moment will not be cancelled.
    func deactivate() {
        isActive = false
    }
    
    /// Executes the action immediately or postpones the action if another async action is executing at the moment.
    /// Actions from pipeline are executed serially in FIFO order, right after the previous action finished dispatching.
    ///
    /// - Parameters:
    ///   - action: The action to dispatch.
    func dispatch<T: Action>(_ action: T) where T.Dispatcher == Self {
        if !isActive || isDispatching {
            pipeline.append({ [weak self] in
                await self?.execute(action)
                await self?.flush()
            })
        } else {
            isDispatching = true
            Task {
                await execute(action)
                await flush()
            }
        }
    }

    /// Executes the action unconditionally bypassing pipelining. Action will be passed through middlewares.
    ///
    /// - Parameter action: The action to execute.
    func execute<T: Action>(_ action: T) async where T.Dispatcher == Self {
        let shouldExecute = middlewares.reduce(into: true) { (result, middleware) in
            if result {
                result = middleware.dispatcher(self, shouldExecute: action)
            }
        }
        
        if shouldExecute  {
            middlewares.forEach { $0.dispatcher(self, willExecute: action) }
            await action.execute(with: self)
            middlewares.forEach { $0.dispatcher(self, didExecute: action) }
        }
    }
}


internal extension Dispatcher {
    
    /// Try to flush the pipeline by executing next action
    func flush() async {
        if isActive, let next = pipeline.popFirst() {
            await next()
        } else {
            isDispatching = false
        }
    }
}
