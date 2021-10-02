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

public class Pipeline {
    
    public typealias Action = () async -> Void
    
    internal class Step {
        let action: Action
        var next: Step?
        
        init(_ action: @escaping Action) {
            self.action = action
        }
    }

    public var isEmpty: Bool {
        return head == nil
    }
    
    internal var head: Step? {
        didSet { if head == nil { tail = nil } }
    }
    
    internal var tail: Step?
    
    public init() {}
    
    /// Adds the action to the end of the pipeline
    public func postpone(_ action: @escaping Action) {
        let step = Step(action)
        if let last = tail {
            last.next = step
            tail = step
        } else {
            head = step
            tail = head
        }
    }
    
    /// Executes next action from the pipeline.
    /// - Returns True when the pipeline is empty. Otherwise executes the next action and returns false.
    public func flush() async -> Bool {
        if let step = head {
            head = step.next
            await step.action()
            return false
        }
        return true
    }
    
    /// Clears the pipeline from the actions
    public func clear() {
        head = nil
    }
}
