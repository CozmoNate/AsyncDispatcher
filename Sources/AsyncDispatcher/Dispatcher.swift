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
    
    typealias Block = () async -> Void
    typealias Pipeline = Deque<Block>
    
    /// The queue of actions
    var pipeline: Pipeline { get set }
    
    /// The list of objects receiving event when the action is about to execute and decide if the action should be allowed to execute
    var middlewares: [Middleware] { get set }
    
    /// The flag indicating that an action is allowed to be executed
    var isActive: Bool { get set }
    
    /// The flag indicating that an action is being dispatched right now
    var isDispatching: Bool { get set }
}

public extension Dispatcher {
    
    /// Activates the dispatcher and starts dispatching actions.
    func activate() {
        isActive = true
        if !isDispatching {
            flush()
        }
    }
    
    /// Deactivates the dispatcher.
    /// All new actions dispatched will be postponed and put waiting until dispatcher is active again.
    /// Action which being executed at the moment will not be cancelled.
    func deactivate() {
        isActive = false
    }
    
    /// Puts the action into the pipeline of actions and execute it in the next cycles.
    /// Actions are executed serially in FIFO order.
    /// Only one action will be executed at a time and dispatcher will wait until it finished to execute next action.
    /// There is no restrictions on direct execution or dispatching of other actions inside action body.
    ///
    /// - Parameters:
    ///   - action: The action to dispatch.
    func dispatch<T: Action>(_ action: T) where T.Dispatcher == Self {
        pipeline.append({ [weak self] in
            await self?.execute(action)
            await self?.flush()
        })
        if !isDispatching {
            flush()
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
    func flush() {
        if isActive, let next = pipeline.popFirst() {
            isDispatching = true
            Task { await next() }
        } else {
            isDispatching = false
        }
    }
}
