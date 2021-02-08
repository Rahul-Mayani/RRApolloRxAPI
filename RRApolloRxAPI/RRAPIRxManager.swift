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

// MARK: - Interceptor
class CustomInterceptor: ApolloInterceptor {
    func interceptAsync<Operation: GraphQLOperation>(chain: RequestChain, request: HTTPRequest<Operation>, response: HTTPResponse<Operation>?, completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) {
        let token = "b2b980b80e4154cb8cdd1d3b156d7b5d17f5eeb3ba3b1035db39cc842b199866"
        if !token.isEmpty {
            request.addHeader(name: "Authorization", value: "Bearer \(token)")
        }
        //request.addHeader(name: "x-secret", value: "IqJjkghjkgjghjQ==")
        chain.proceedAsync(request: request, response: response, completion: completion)
    }
}

class NetworkInterceptorProvider: LegacyInterceptorProvider {
    override func interceptors<Operation: GraphQLOperation>(for operation: Operation) -> [ApolloInterceptor] {
        var interceptors = super.interceptors(for: operation)
        interceptors.insert(CustomInterceptor(), at: 0)
        return interceptors
    }
}

// MARK: - `Singleton` class
final class APIManager {

    /// variable of Singleton
    static let shared = APIManager()
    
    private init() {}
    
    private let basrUrl = "https://graphql.contentful.com/content/v1/spaces/qz0n5cdakyl9/environments/master"
    
    /// `WebSocketTransport`
    private lazy var webSocketTransport: WebSocketTransport = {
        let url = URL(string: basrUrl)!
        var request = URLRequest(url: url)
        var authPayload = GraphQLMap()
        let token = "b2b980b80e4154cb8cdd1d3b156d7b5d17f5eeb3ba3b1035db39cc842b199866"
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return WebSocketTransport(request: request, connectingPayload: authPayload)
    }()
    
    /// `RequestChainNetworkTransport`
    private lazy var normalTransport: RequestChainNetworkTransport = {
        let client = URLSessionClient()
        let provider = NetworkInterceptorProvider(client: client, store: self.store)
        let url = URL(string: basrUrl)!
        return RequestChainNetworkTransport(interceptorProvider: provider, endpointURL: url)
    }()

    /// `ApolloStore`
    private lazy var store: ApolloStore = {
        let store: ApolloStore!
        do {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let documentsURL = URL(fileURLWithPath: documentsPath)
            let sqliteFileURL = documentsURL.appendingPathComponent("RRApolloRxAPI.sqlite")
            let sqliteCache = try SQLiteNormalizedCache(fileURL: sqliteFileURL)
            store = ApolloStore(cache: sqliteCache)
        } catch {
            let cache = InMemoryNormalizedCache()
            store = ApolloStore(cache: cache)
        }
        store.cacheKeyForObject = { $0["id"] }
        return store
    }()
    
    /// `SplitNetworkTransport`
    private lazy var splitNetworkTransport = SplitNetworkTransport(
      uploadingNetworkTransport: self.normalTransport,
      webSocketNetworkTransport: self.webSocketTransport
    )

    /// `ApolloClient`
    private(set) lazy var client = ApolloClient(networkTransport: self.splitNetworkTransport, store: self.store)
}

// MARK: - API methods in extension
extension APIManager {
    
    /// `Mutation` query
    func rxPerform<Mutation: GraphQLMutation>(mutation: Mutation, queue: DispatchQueue = DispatchQueue.main, isLoader : Bool = false) -> Maybe<Mutation.Data> {
        
        if isLoader {
            //AppLoader.startLoaderToAnimating()
        }
        
        return Maybe.create { maybe in
            
            let cancellable = APIManager.shared.client.perform(mutation: mutation, queue: queue) { result in
                
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
    
    /// `Watch` query
    func rxWatch<Query: GraphQLQuery>(
        query: Query,
        cachePolicy: CachePolicy = .fetchIgnoringCacheData,
        isLoader : Bool = true) -> Observable<Query.Data> {
        
        if isLoader {
           //AppLoader.startLoaderToAnimating()
        }
        
        return Observable.create { observer in
          
            let watcher = APIManager.shared.client.watch(query: query, cachePolicy: cachePolicy) { result in
                
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
    
    /// `Fetch` query
    func rxFetch<Query: GraphQLQuery>(
        query: Query,
        cachePolicy: CachePolicy = .fetchIgnoringCacheData,
        queue: DispatchQueue = DispatchQueue.main,
        isLoader : Bool = true) -> Maybe<Query.Data> {
        
        if isLoader {
            //AppLoader.startLoaderToAnimating()
        }
        
        return Maybe.create { maybe in
            
            let cancellable = APIManager.shared.client.fetch(query: query, cachePolicy: cachePolicy, queue: queue) { result in
                
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
    
    // MARK: - Socket connection
    func diconnectSocket() {
        if webSocketTransport.isConnected() {
            webSocketTransport.pauseWebSocketConnection()
        }
    }
    
    func reconnectSocket() {
        if !webSocketTransport.isConnected() {
            webSocketTransport.resumeWebSocketConnection()
        }
    }
}

// MARK: - Thread Scheduler
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
