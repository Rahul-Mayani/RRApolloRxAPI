//
//  RRAPIRxManager.swift
//  RRApolloRxAPI
//
//  Created by Rahul Mayani on 23/12/19.
//  Copyright © 2019 RR. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift
import Apollo

class APIManager {

    static let shared = APIManager()
    
    private static func apollo() -> ApolloClient {
        let configuration = URLSessionConfiguration.default

        let token = "b2b980b80e4154cb8cdd1d3b156d7b5d17f5eeb3ba3b1035db39cc842b199866"
        if !token.isEmpty {
            configuration.httpAdditionalHeaders = ["Authorization": "Bearer \(token)"]
        }
        let url = URL(string: "https://graphql.contentful.com/content/v1/spaces/qz0n5cdakyl9/environments/master")!

        let store = ApolloStore(cache: InMemoryNormalizedCache())
        
        let session = URLSession.init(configuration: configuration)
        
        return ApolloClient(networkTransport: HTTPNetworkTransport(url: url, session: session), store: store)
    }
    
    func rxPerform<Mutation: GraphQLMutation>(mutation: Mutation, queue: DispatchQueue = DispatchQueue.main, isLoader : Bool = false) -> Maybe<Mutation.Data> {
        
        if isLoader {
            //AppLoader.startLoaderToAnimating()
        }
        
        return Maybe.create { maybe in
            
            let cancellable = APIManager.apollo().perform(mutation: mutation, queue: queue) { result in
                
                //AppLoader.stopLoaderToAnimating()
                
                switch result {
                case .success(let graphQLResult):
                  if let exception = graphQLResult.errors?.first?.extensions?["exception"] as? [String : Any], let code = exception["status"] as? Int, code == 401 {
                      //AppLogout.logout()
                      return
                  }
                  guard let data = try? result.get().data else {
                      maybe(.error((graphQLResult.errors?.first!)!))
                      return
                  }
                  maybe(.success(data))
                case .failure(let error):
                  maybe(.error(error))
                }
            }

            return Disposables.create {
                cancellable.cancel()
            }
        }
    }
    
    func rxWatch<Query: GraphQLQuery>(
        query: Query,
        cachePolicy: CachePolicy = .fetchIgnoringCacheData,
        queue: DispatchQueue = DispatchQueue.main,
        isLoader : Bool = true) -> Observable<Query.Data> {
        
        if isLoader {
           //AppLoader.startLoaderToAnimating()
        }
        
        return Observable.create { observer in
           
            let watcher = APIManager.apollo().watch(query: query, cachePolicy: cachePolicy, queue: queue) { result in
                
                //AppLoader.stopLoaderToAnimating()
                
                switch result {
                case .success(let graphQLResult):
                  guard let data = try? result.get().data else {
                      observer.onError((graphQLResult.errors?.first!)!)
                      return
                  }
                  observer.onNext(data)
                case .failure(let error):
                  observer.onError(error)
                }
            }

            return Disposables.create {
                watcher.cancel()
            }
        }
    }
    
    func rxFetch<Query: GraphQLQuery>(
        query: Query,
        cachePolicy: CachePolicy = .fetchIgnoringCacheData,
        queue: DispatchQueue = DispatchQueue.main,
        isLoader : Bool = true) -> Maybe<Query.Data> {
        
        if isLoader {
            //AppLoader.startLoaderToAnimating()
        }
        
        return Maybe.create { maybe in
            
            let cancellable = APIManager.apollo().fetch(query: query, cachePolicy: cachePolicy, queue: queue) { result in
                
                //AppLoader.stopLoaderToAnimating()
                
                switch result {
                case .success(let graphQLResult):
                  if let exception = graphQLResult.errors?.first?.extensions?["exception"] as? [String : Any], let code = exception["status"] as? Int, code == 401 {
                      //AppLogout.logout()
                      return
                  }
                  guard let data = try? result.get().data else {
                      maybe(.error((graphQLResult.errors?.first!)!))
                      return
                  }
                  maybe(.success(data))
                case .failure(let error):
                  maybe(.error(error))
                }
            }

            return Disposables.create {
                cancellable.cancel()
            }
        }
    }
}



public struct RXScheduler {
    static let main = MainScheduler.instance
    static let concurrentMain = ConcurrentMainScheduler.instance

    static let serialBackground = SerialDispatchQueueScheduler.init(qos: .background)
    static let concurrentBackground = ConcurrentDispatchQueueScheduler.init(qos: .background)

    static let serialUtility = SerialDispatchQueueScheduler.init(qos: .utility)
    static let concurrentUtility = ConcurrentDispatchQueueScheduler.init(qos: .utility)

    static let serialUser = SerialDispatchQueueScheduler.init(qos: .userInitiated)
    static let concurrentUser = ConcurrentDispatchQueueScheduler.init(qos: .userInitiated)

    static let serialInteractive = SerialDispatchQueueScheduler.init(qos: .userInteractive)
    static let concurrentInteractive = ConcurrentDispatchQueueScheduler.init(qos: .userInteractive)
}
