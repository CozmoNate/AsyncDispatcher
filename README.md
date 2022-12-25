# AsyncDispatcher

[![License](https://img.shields.io/badge/license-MIT-ff69b4.svg)](https://github.com/kzlekk/AsyncDispatcher/raw/master/LICENSE)
![Language](https://img.shields.io/badge/swift-5.5-orange.svg)
![Coverage Status](https://img.shields.io/badge/coverage-100%25-brightgreen)

**AsyncDispatcher** is a library utilizing actors and async/await mechanics and ensures that all operations (called actions) are dispatched and executed serially. **AsyncDispatcher** can be used for state management of domain logic components or/and UI components.

## Installation

### Swift Package Manager

Add "AsyncDispatcher" dependency via integrated Swift Package Manager in XCode

## Usage

Dispatcher can be either global or main thread actor. The state itself and dispatching actions can adopt separated actor to perform changes with.

Example of store object conforming to **Dispatcher** protocol adopting global actor for dispatching actions, but uses main actor for state access: 

```swift

    @globalActor actor CounterStore: Dispatcher, GlobalActor {
       
        static var shared = CounterStore()
                   
        // The state accessible only from the main thread
        @MainActor var count: Int = 0
        
        var pipeline = Pipeline()
        var middlewares = [] as Array<Middleware>
        var isDispatching = false
    }
    
```

State management of the **Dispatcher** is done via dispatching well known actions. Each action implements its own logic how the for dispatcher's state should be modified.

Example **Action** implementation which is tied to the **CounterDispatcher** from the example above:
 
```swift

    extension CounterStore {
     
        struct Increment: Action {
        
            let value: Int = 1
        
            @MainActor func execute(with store: CounterStore) async {
                store.value += value // Values is allowed to be accessed directly from the main thread
            }
        }
    }
    
```

It is possible to execute actions from another action allowing to make action composition:
 
```swift

    extension CounterStore {
     
        struct IncrementByThree: Action {
        
            // This action is executing from CounterStore's background actor context
            @CounterStore func execute(with store: CounterStore) async {
                await store.execute(Increment())
                await store.execute(Increment())
                await store.execute(Increment())
            }
        }
    }
    
```

To change the state of the **CounterStore** from the examples above, we need to dispatch supported action:

```swift

    Task { @MaiActor in 
    
        let counterStore = CounterStore()
    
        await [
            counterStore.dispatch(CounterStore.Increment()), 
            counterStore.dispatch(CounterStore.Increment(value: 10))
        ]
        
        print(counterStore.count) // Should print: 11
    }
    
```

If there is a possibility to use some sort of dependency injection, we can simplify action dispatching code even more:

```swift

    protocol CounterStoreAction where Dispatcher == CounterStore {}
    
    extension CounterStoreAction {
        func dispatch() async {
            await Dependencies.default.counterStore.dispatch(self)
        }
        
        func schedule() {
            Task { await CounterStore.shared.dispatch(self) }
        }
    }
    
    extension CounterStore {     
        struct IncrementByOne: CounterStoreAction {
            @MainActor func execute(with store: CounterStore) async {
                store.value += 1
            }
        }
    }
    
    // Dispatches the action to singleton store to be executed the main thread. 
    // This way it can be safely dispatched from any point in the code.
    CounterStore.IncrementByOne().schedule()


``` 
