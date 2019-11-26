# Combine 🎅

## 1. Publisher와 Subscriber 

- Subscriber는 Publisher를 subscribe한다 

  Publisher는 데이터를 emit 한다. 

- Publisher는 프로토콜이고 AnyPublisher는 Publisher을 따르는 struct
  Subscriber는 프로토콜이고 AnySubscriber는 Subscriber를 따르는 struct



```swift
import UIKit
import Combine

class ViewController: UIViewController {
    
    private var cancelBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        Just(1).sink(receiveCompletion: { (completion) in
            print("recevieCompletion \(completion)")
        }) { value in
            print("recevieCompletion \(value)")
        }.store(in: &cancelBag)
    }
}

// print 
recevieCompletion 1
recevieCompletion finished
```



값을 방출하는 `Just(1)` 은 `publisher` 

방출되는 값을 구독하여 프린트해주는 `sink` 블럭은 `subscriber` 라고 할 수 있겠습니다.

명시적으로 써주면 이렇게 되겠죠...?


```swift
import UIKit
import Combine

class ViewController: UIViewController {
    
    private var cancelBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        let publisher = Just(1)
        let subscriber = publisher.sink(receiveCompletion: { (completion) in
            print("recevieCompletion \(completion)")
        }) { value in
            print("recevieCompletion \(value)")
        }.store(in: &cancelBag)
    }
}

// print 
1 
```



### 1.1 Subscriber 



이번엔 subscriber를 아예 만들어서 써보겠습니다. 


```swift
class ViewController: UIViewController {
    
    private var cancelBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let publisher = Just(1)
        
        let subscriber = AnySubscriber<Int, Never>(receiveSubscription: { (subscription) in
            print("receive Subscription \(subscription)")
            subscription.request(.unlimited)
        }, receiveValue: { value -> Subscribers.Demand in
            print("receive Value \(value)")
            return .none
        }) { (completion) in
            print("recevieCompletion \(completion)")
        }
        
        publisher.subscribe(subscriber)
    }
}

// print 
receive Subscription Just
receive Value 1
recevieCompletion finished
```



1) receiveSubscription 블럭에서 방출되는 몇개의 값을 받을 것인지 지정해줍니다.
` subscription.request(.unlimited)` 를 해서 제한없이 방출되는 값을 모두 받겠다! 라고 해줍니다

이렇게 옵션이 있는데, none을 지정해주면 방출되는 값 중 아무것도 안받고 (실제 receive Value 가 안불림) max로 최대 몇 개의 값을 받을 것인지 지정해줄 수 있습니다. ( 1.1.1에서 보여드림)


<img width="518" alt="스크린샷 2019-11-26 오후 10 23 55" src="https://user-images.githubusercontent.com/9502063/69637148-70671300-109b-11ea-9599-144a8498faa2.png">



2) receiveValue 블럭에서는 방출된 값이 들어오고 1에서 말해준 요구사항을 재확인(?) 해주는 의미로 Demand를 return 해줍니다 

.none을 리턴해주고 위에 적은 요구사항을 바꾸지 않을거야! 해줍니다. 



=> 여러 조합으로 좀 더 테스트가 필요함. 



3) receiveCompletion 블럭은 finished 되었을 때 불립니다. 



저렇게 써서 가독성이 안좋거나 항상 똑같은 설정으로 해주고 싶다면, 

`Subscriber` 프로토콜을 채택한 클래스나 구조체를 만들어줘서 쓰시면 됩니다. 



```swift
struct CustomSubscriber: Subscriber {
    
    func receive(subscription: Subscription) {
        print("receive Subscription \(subscription)")
        subscription.request(.max(1))
    }
    
    func receive(_ input: Int) -> Subscribers.Demand {
        print("receive Value \(input)")
        return .none
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        print("recevieCompletion \(completion)")
    }
    
    typealias Input = Int
    typealias Failure = Never
    
    var combineIdentifier: CombineIdentifier
}

class ViewController: UIViewController {
    
    private var cancelBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let publisher = Just(1)
        let subscriber = CustomSubscriber(combineIdentifier: CombineIdentifier(combineIdentifier: CombineIdentifier()))
        publisher.subscribe(subscriber)
    }
}

// print 

receive Subscription Just
receive Value 1
recevieCompletion finished
```



combineIdentifier 는 뭐하는 녀석인지 좀 더 알아봐야겠습니다 -!





### 1.1.1 Subscribers.Demand 

##### 1. Max 

```swift
struct CustomSubscriber: Subscriber {
    
    func receive(subscription: Subscription) {
        print("receive Subscription \(subscription)")
      
        // 최대 3개의 아이템만 받을 거야..!!
        // 구독하는 Publisher가 100개를 보내도 나는 3개만 받을거야.
        subscription.request(.max(3))
    }
    
    func receive(_ input: Int) -> Subscribers.Demand {
        print("receive Value \(input)")
        // 위에서 했던 요구사항을 바꾸지 않을거야.
        return .none
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        print("recevieCompletion \(completion)")
    }
    
    typealias Input = Int
    typealias Failure = Never
    
    var combineIdentifier: CombineIdentifier
}

class ViewController: UIViewController {
    
    private var cancelBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let publisher = [1,2,3,4,5,6].publisher
        let subscriber = CustomSubscriber(combineIdentifier: CombineIdentifier())
        publisher.subscribe(subscriber)
    }
}

// print 
receive Subscription [1, 2, 3, 4, 5, 6]
receive Value 1
receive Value 2
receive Value 3
```

 딱 세 개의 value만 받습니다...!! 근데 finish가 안되나봅니다. 



##### 2. unlimited 

```swift
struct CustomSubscriber: Subscriber {
    
    func receive(subscription: Subscription) {
        print("receive Subscription \(subscription)")
        // 제한 없이 모든 값을 받을 거야.
        subscription.request(.unlimited)
    }
    
    func receive(_ input: Int) -> Subscribers.Demand {
        print("receive Value \(input)")
        // 위에서 했던 요구사항을 바꾸지 않을거야.
        return .none
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        print("recevieCompletion \(completion)")
    }
    
    typealias Input = Int
    typealias Failure = Never
    
    var combineIdentifier: CombineIdentifier
}

class ViewController: UIViewController {
    
    private var cancelBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let publisher = [1,2,3,4,5,6].publisher
        let subscriber = CustomSubscriber(combineIdentifier: CombineIdentifier())
        publisher.subscribe(subscriber)
    }
}


// print 
receive Subscription [1, 2, 3, 4, 5, 6]
receive Value 1
receive Value 2
receive Value 3
receive Value 4
receive Value 5
receive Value 6
recevieCompletion finished
```



##### 3. none 

```swift 
struct CustomSubscriber: Subscriber {
    
    func receive(subscription: Subscription) {
        print("receive Subscription \(subscription)")
        // 아무 값도 받지 않을거야.
        subscription.request(.none)
    }
    
    func receive(_ input: Int) -> Subscribers.Demand {
        print("receive Value \(input)")
        // 위에서 했던 요구사항을 바꾸지 않을거야.
        return .none
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        print("recevieCompletion \(completion)")
    }
    
    typealias Input = Int
    typealias Failure = Never
    
    var combineIdentifier: CombineIdentifier
}

class ViewController: UIViewController {
    
    private var cancelBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let publisher = [1,2,3,4,5,6].publisher
        let subscriber = CustomSubscriber(combineIdentifier: CombineIdentifier())
        publisher.subscribe(subscriber)
    }
}


// print 
receive Subscription [1, 2, 3, 4, 5, 6] 
```

