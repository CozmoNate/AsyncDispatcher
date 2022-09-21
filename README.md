# AsyncDispatcher

[![License](https://img.shields.io/badge/license-MIT-ff69b4.svg)](https://github.com/kzlekk/AsyncDispatcher/raw/master/LICENSE)
![Language](https://img.shields.io/badge/swift-5.5-orange.svg)
![Coverage Status](https://img.shields.io/badge/coverage-96.7%25-brightgreen)

AsyncDispatcher is a lightweight **Dispatcher** implementation of **Flux** pattern. 

**Dispatcher** protocol provides methods and properties allowing to control data flow by sending and handling actions serially but still executing them asynchronously using async/await pattern if needed. **Dispatcher** is intended to use for state management of business logic components. It can be used as higher level model for UI components in some cases, but not designed to be a view model replacement. Current **Dispatcher** design is based on the experience from building couple of commercial and personal projects, and efforts of simplifying state management code and trying not to dictate state container implementation too much.

## Installation

### Swift Package Manager

Add "AsyncDispatcher" dependency via integrated Swift Package Manager in XCode

## Usage

Dispatcher is just a protocol, so it does not define strictly, how the state management machine should be look like, and can be adopted to nearly any class.

Example of store object conforming to **Dispatcher** protocol: 

```swift

    class CounterStore: Dispatcher {
       
        var pipeline = Pipeline()
        var middlewares = [] as Array<Middleware>
        var isDispatching = false
        
        // The state
        var count: Int = 0
    }
    
```

State management of the **Dispatcher** is done via dispatching well known actions. Each action implements its own logic how the for dispatcher's state should be modified.

Example **Action** implementation which is tied to the **CounterDispatcher** from the example above:
 
```swift

    extension CounterStore {
     
        struct Increment: Action {
        
            let value: Int = 1
        
            func execute(with store: CounterStore) async {
                store.value += value
            }
        }
    }
    
```

It is possible to execute actions from another action allowing to make action composition:
 
```swift

    extension CounterStore {
     
        struct IncrementByThree: Action {
            func execute(with store: CounterStore) async {
                await store.execute(Increment())
                await store.execute(Increment())
                await store.execute(Increment())
            }
        }
    }
    
```

To change the state of the **CounterStore** from the examples above, we need to dispatch supported action:

```swift
    
    let counterStore = CounterStore()
    
    async let one = counterStore.dispatch(CounterStore.Increment())
    async let ten = counterStore.dispatch(CounterStore.Increment(value: 10))
    
    await [one, ten]
    
    print(counterStore.count) // Should print: 11
    
```

If there is a possibility to use some sort of dependency injection, we can simplify action dispatching code even more:

```swift

    protocol CounterStoreAction where Dispatcher == CounterStore {}
    
    extension CounterStoreAction {
        @MainActor func dispatch() {
            await Dependencies.default.counterStore.dispatch(self)
        }
        
        func dispatch() {
            Task { @MainActor in
                await Dependencies.default.counterStore.dispatch(self)
            }
        }
    }
    
    extension CounterStore {     
        struct IncrementByOne: CounterStoreAction {
            func execute(with store: CounterStore) async {
                store.value += 1
            }
        }
    }
    
    // Dispatches the action to singleton store to be executed the main thread. 
    // This way it can be safely dispatched from any point in the code.
    CounterStore.IncrementByOne().dispatch()


``` 

## Advanced Usage

### Concurrent access and race conditions

AsyncDispatcher does not implement any thread safety mechanism by default allowing developers to decide on synchronization mechanics suitable for their specific use cases.

As an example of basic thread safety, you can extend default **Action** and specify it for synchronous **Dispatcher** as following:

```swift

import AsyncDispatcher

public protocol ActingDispatcher: AsyncDispatcher.Dispatcher {
    
    // This method always dispatches actions using synchronization mechanic decided by Dispatcher 
    func schedule<T: Action>(_ action: T) async where T.Dispatcher == Self
}

public protocol DispatchingAction: Action where Self.Dispatcher: ActingDispatcher {
    
    var defaultDispatcher: Self.Dispatcher { get }
    
    func dispatch() async
    func schedule(completion: (() -> Void)?)
    func schedule(after delay: DispatchTime, completion: (() -> Void)?)
}

public extension DispatchingAction {
    
    func dispatch() async {
        await defaultDispatcher.schedule(self)
    }
    
    func schedule(completion: (() -> Void)? = nil) {
        Task {
            await defaultDispatcher.schedule(self)
            completion?()
        }
    }
    
    func schedule(after delay: DispatchTime, completion: (() -> Void)? = nil) {
        DispatchQueue.global().asyncAfter(deadline: delay) { 
            Task {
                await defaultDispatcher.schedule(self)
                completion?()
            }
        }
    }
}


```

And following is the implementation of basic background queue **ActingDispatcher** which uses **globalActor**. This one uses **globalActor** to dispatch actions on background thread. This is related to only dispatching and executing actions. Accessing state can be implemented via the same or any other actor. Actions can decide themselves which actor they are using when *execute* function called by dispatcher.

```swift

// Actions adopting SimpleFlowAction will be scheduled using shared SimpleFlow dispatcher and on background thread.
// This does not enforce the action to perform *execute* function with the same actor, it can use any other actor
public protocol SimpleFlowAction: DispatchingAction, where Dispatcher == SimpleFlow {}

public extension SimpleFlowAction {
    
    var defaultDispatcher: SimpleFlow {
        SimpleFlow.sharedDispatcher
    }
}

@globalActor final actor SimpleFlowActor: GlobalActor {
    
    static let shared = SimpleFlowActor()
}

public final class SimpleFlow: ActingDispatcher {
    
    public static let sharedDispatcher = SimpleFlow()
    
    // These must be accessed from the same actor which was used to execute actions
    public var pipeline = Pipeline()
    public var middlewares = []
    public var isDispatching = false
    
    public func schedule<T>(_ action: T) async where SimpleFlow == T.Dispatcher, T : Action {
        await Task { @SimpleFlowActor in await dispatch(action) }.value
    }
}

```
