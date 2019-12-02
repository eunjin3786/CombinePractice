# Combine 🎅

## 1. Publisher와 Subscriber 

- Subscriber는 Publisher를 subscribe한다  
  Publisher는 데이터를 emit 한다. 

- Publisher는 프로토콜이고 AnyPublisher는 Publisher을 따르는 struct  
  Subscriber는 프로토콜이고 AnySubscriber는 Subscriber를 따르는 struct


### 예제 

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
          print("recevieValue \(value)")
      }.store(in: &cancelBag)
  }
}

// print 
recevieValue 1
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
recevieValue 1
recevieCompletion finished
```



### 1.1 Subscriber 

### 1.1.1 쉽게 만드는 Subsriber

<img width="581" alt="스크린샷 2019-12-01 오후 5 12 52" src="https://user-images.githubusercontent.com/9502063/69911364-d10c9c00-145d-11ea-9a4d-c83fe96752da.png">



위에서 봤던 예제처럼 `sink` 함수를 이용하여 쉽게 subscribe 할 수 있습니다. 



### 1.1.2 아예 만드는 Subsriber

이번엔 subscriber를 아예 만들어서 써보겠습니다. 

#### Option 1


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



  1. receiveSubscription 블럭에서 방출되는 몇개의 값을 받을 것인지 지정해줍니다.  
     `subscription.request(.unlimited)`를 해서 제한없이 방출되는 값을 모두 받겠다! 라고 해줍니다  
     
     이렇게 옵션이 있는데,  
     
     <img width="518" alt="스크린샷 2019-11-26 오후 10 23 55" src="https://user-images.githubusercontent.com/9502063/69637148-70671300-109b-11ea-9599-144a8498faa2.png">  
     
     none을 지정해주면 방출되는 값 중 아무것도 안받고 (실제 receive Value 가 안불림)  
     max로 최대 몇 개의 값을 받을 것 인지 지정해주면 딱 그만큼의 값만 받습니다.  
     ('추가) Subscribers.Demand의 종류' 를 참고하세요)
     
     

  2. receiveValue 블럭에서는 방출된 값이 들어오고 1에서 말해준 요구사항을 재확인(?) 해주는 의미로 Demand를 return 해줍니다 
     `.none`을 리턴해주며 위에 적은 요구사항을 바꾸지 않을거야! 해줍니다.  
     
     => 1과 2는 여러 조합으로 좀 더 테스트가 필요할 것 같습니다. 



  3. receiveCompletion 블럭은 finished 되었을 때 불립니다.

     


#### Option 2

저렇게 써서 가독성이 안좋게 느껴지거나 항상 똑같은 설정의 `Subscriber`를 사용하고 싶다면,    
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

   



### 추가) Subscribers.Demand의 종류



#### 1. Max 

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



#### 2. unlimited 

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



#### 3. none 

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

### 1.2 Publisher

### 1.2.1 쉽게 만드는 Publisher 

#### 1.2.1.1 Just 



<img width="743" alt="스크린샷 2019-12-01 오후 4 50 20" src="https://user-images.githubusercontent.com/9502063/69911159-aa993180-145a-11ea-90e3-7cb8acdaaf9f.png">



```swift
class ViewController: UIViewController {
    
    private var cancelBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // publisher의 타입은 Just<Int> 
        let publisher = Just(1)
        publisher.sink(receiveCompletion: { (completion) in
            print(completion)
        }) { (value) in
            print(value)
        }.store(in: &cancelBag)
    }
}

// print 
1
finished 
```



#### 1.2.1.2 시퀀스 타입.publisher 

<img width="747" alt="스크린샷 2019-12-01 오후 4 43 39" src="https://user-images.githubusercontent.com/9502063/69911117-bcc6a000-1459-11ea-93f2-4ebbc49de66c.png">



```swift
class ViewController: UIViewController {
    
    private var cancelBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // publisher의 타입은 Publishers.Sequence<[Int], Never>  
        let publisher = [1,2,3,4,5,6].publisher
        publisher.sink(receiveCompletion: { (completion) in
            print(completion)
        }) { (value) in
            print(value)
        }.store(in: &cancelBag)
    }
}


// print
1
2
3
4
5
6
finished
```

```swift
class ViewController: UIViewController {
    
    private var cancelBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
       // publisher의 타입은 Publishers.Sequence<String, Never>
        let publisher = "123".publisher
        publisher.sink(receiveCompletion: { (completion) in
            print(completion)
        }) { (value) in
            print(value)
        }.store(in: &cancelBag)
    }
}



// print
1
2
3
finished
```



### 1.2.2 아예 만드는 Publisher 

위의  `AnySubscriber`  의 이니셜라이저는 이렇게 되어있습니다.   

우리는 두번째 이니셜라이저로 커스텀한 Subscriber을 만들었습니다. 

<img width="753" alt="스크린샷 2019-12-01 오후 5 01 36" src="https://user-images.githubusercontent.com/9502063/69911263-3d869b80-145c-11ea-9077-633844047885.png">



하지만 Publisher의 이니셜라이저는 하나밖에 없어서 커스텀한 Publisher를 못만드는 것 같습니다. 

<img width="753" alt="스크린샷 2019-12-01 오후 5 02 13" src="https://user-images.githubusercontent.com/9502063/69911268-542cf280-145c-11ea-9d37-35aa6d25e0d0.png"> 



저 P에 Publisher를 넘겨줘야하는 것 같은데 어떻게 하는 지 모르겠네요 

<img width="480" alt="스크린샷 2019-12-01 오후 5 05 53" src="https://user-images.githubusercontent.com/9502063/69911311-d6b5b200-145c-11ea-9d7c-c4d357cbb6a1.png"> 





## 2. Subject 

- Publisher와 Subscriber 역할을 모두 할 수 있다. 



### 2.1 PassthroughSubject

#### 예제

```swift
class ViewController: UIViewController {
    
    private var cancelBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let subject = PassthroughSubject<Int, Never>()
        
        subject.sink(receiveCompletion: { (completion) in
            print(completion)
        }) { value in
            print(value)
        }.store(in: &cancelBag)
        
        subject.send(1)
        subject.send(2)
        subject.send(completion: .finished)
    }
}

// print
1
2
finished
```



### 2.2 PassthroughSubject

- 초기값을 가지는 Subject

#### 예제

```swift
class ViewController: UIViewController {
    
    private var cancelBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let subject = CurrentValueSubject<Int, Never>(100)
        
        subject.sink(receiveCompletion: { (completion) in
            print(completion)
        }) { value in
            print(value)
        }.store(in: &cancelBag)

        subject.send(1)
        subject.send(2)
        subject.send(completion: .finished)
    }
}

// print
100
1
2
finished
```



### 2.3 추가 

#### 2.3.1 cancel 함수로 구독을 취소할 수 있음. 

```swift
class ViewController: UIViewController {
    
    private var cancelBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let subject = PassthroughSubject<Int, Never>()
        
        let subscriber = subject.sink(receiveCompletion: { (completion) in
            print(completion)
        }) { value in
            print(value)
        }
        subscriber.store(in: &cancelBag)

        subject.send(1)
        subject.send(2)
        
        subscriber.cancel()
        
        subject.send(3)
        subject.send(4)
    }
}


// print
1
2
```



#### 2.3.2 eraseToAnyPublisher 

```swift
let subject = PassthroughSubject<Int, Never>()

// subject의 타입은 PassthroughSubject<Int, Never> 
```



```swift
let subject = PassthroughSubject<Int, Never>().eraseToAnyPublisher()

// subject의 타입은 AnyPublisher<Int, Never>
```



