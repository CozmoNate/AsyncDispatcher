# AsyncDispatcher

[![License](https://img.shields.io/badge/license-MIT-ff69b4.svg)](https://github.com/kzlekk/AsyncDispatcher/raw/master/LICENSE)
![Language](https://img.shields.io/badge/swift-5.5-orange.svg)
![Coverage Status](https://img.shields.io/badge/coverage-96%25-brightgreen)

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
    
        @Inject(\.counterStore) // Injected from IoC container 
        var store: CounterStore
        
        func dispatch() {
            store.dispatch(self)
        }
    }
    
    extension CounterStore {     
        struct IncrementByOne: CounterStoreAction {
            func execute(with store: CounterStore) async {
                store.value += 1
            }
        }
    }
    
    // Dispatches the action to singleton store. This way it can be safely dispatched from any point in the code.
    CounterStore.IncrementByOne().dispatch()


``` 
