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

public protocol Middleware {
    
    /// This method is called by the dispatcher before executing the action
    /// - Parameters:
    ///   - dispatcher: The dispatcher that would execute the action
    ///   - action: The action that should be executed
    func dispatcher<Dispatcher, Action>(_ dispatcher: Dispatcher, shouldExecute action: Action) -> Bool
    
    /// This method is called by the dispatcher right before the action is executed
    /// - Parameters:
    ///   - dispatcher: The dispatcher that executed the action
    ///   - action: The action that has been executed
    func dispatcher<Dispatcher, Action>(_ dispatcher: Dispatcher, willExecute action: Action)
    
    /// This method is called by the dispatcher after the action is executed
    /// - Parameters:
    ///   - dispatcher: The dispatcher that executed the action
    ///   - action: The action that has been executed
    func dispatcher<Dispatcher, Action>(_ dispatcher: Dispatcher, didExecute action: Action)
}
