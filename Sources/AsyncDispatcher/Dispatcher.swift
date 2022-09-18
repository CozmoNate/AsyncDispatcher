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

/// Dispatcher is an object allowing to dispatch actions and provides infrastructure for action to perform job
public protocol Dispatcher: AnyObject {
    
    /// The queue of postponed actions
    var pipeline: Pipeline { get set }
    
    /// The list of objects that are conforming to Middleware protocol and receive events when the action is executed
    var middlewares: [Middleware] { get set }
    
    /// The flag indicating that an action is being dispatched right now
    var isDispatching: Bool { get set }
}

public extension Dispatcher {
    
    /// Executes the action immediately or postpones the action if another async action is executing at the moment.
    /// If dispatched while an async action is executing, the action will be send to the pipeline.
    /// Actions from pipeline are executed serially in FIFO order, right after the previous action finishes dispatching.
    /// - Parameters:
    ///   - action: The action to dispatch.
    func dispatch<T: Action>(_ action: T) async where T.Dispatcher == Self {
        let actionItem: () async -> Void = { [weak self] in
            guard let self = self else { return }
            await self.execute(action)
            await self.flush()
        }
        if isDispatching {
            pipeline.postpone(actionItem)
        } else {
            isDispatching = true
            await actionItem()
        }
    }

    /// Unconditionally executes the action on current queue. NOTE: It is not recommended to execute actions directly.
    /// Use "execute" to apply an action immediately inside async "dispatched" action without locking the queue.
    ///
    /// - Parameter action: The action to execute.
    func execute<T: Action>(_ action: T) async where T.Dispatcher == Self {
        let shouldExecute = middlewares.reduce(into: true) { (result, middleware) in
            guard result else { return }
            result = middleware.dispatcher(self, shouldExecute: action)
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
        if await pipeline.flush() {
            isDispatching = false
        }
    }
}

