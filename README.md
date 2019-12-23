# RRApolloRxAPI
GraphQL (Apollo) API Request by RxSwift


## Requirements

pod 'RxCocoa'

pod 'RxSwift'

pod 'Apollo'

## Installation

#### Manually
1. Download and drop ```RRAPIRxManager.swift``` in your project.
2. Add your GraphQL scema.json file and API end point URL in your project.
3. Setup Apollo Client: https://www.apollographql.com/docs/ios/installation/
4. Congratulations!  

## Usage example
To run the example project, clone the repo, and run pod install from the Example directory first.


```swift

var query: HomeQuery {
    return HomeQuery(slug: "home")
}

APIManager.shared.rxFetch(query: query)
.subscribeOn(RXScheduler.concurrentBackground)
.observeOn(RXScheduler.main)
.subscribe(onSuccess: { response in
    print(response)
}, onError: { error in
    print(error)
}).disposed(by: rxbag)

```

## Contribute

We would love you for the contribution to **RRApolloRxAPI**, check the ``LICENSE`` file for more info.


## License

RRApolloRxAPI is available under the MIT license. See the LICENSE file for more info.
