
import UIKit
import Combine

struct StringSubscriber: Subscriber {
    
    func receive(subscription: Subscription) {
        print("received subscription")
        // 최대 3개의 아이템만 받을 거야..!!
        // 구독하는 Publisher가 100개를 보내도 나는 3개만 받을거야.
        // backpressure 라고 부르심.
        subscription.request(.max(3))
    }
    
    func receive(_ input: String) -> Subscribers.Demand {
        print("received Value")
        // 위에서 했던 요구사항을 바꾸지 않을거야.
        return .none
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        print("Completed")
    }
    
    typealias Input = String
    typealias Failure = Never
    
    var combineIdentifier: CombineIdentifier
}

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

