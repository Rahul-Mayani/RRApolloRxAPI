//
//  ViewController.swift
//  RRApolloRxAPI
//
//  Created by Rahul Mayani on 23/12/19.
//  Copyright © 2019 RR. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Apollo

class ViewController: UIViewController {

    // MARK: - Variable -
    let rxbag = DisposeBag()
    
    var query: HomeQuery {
        return HomeQuery(slug: "home")
    }
    
    // MARK: - View Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        APIManager.shared.rxFetch(query: query)
            .subscribe(on: RXScheduler.concurrentBackground)
            .observe(on: RXScheduler.main)
            .subscribe(onSuccess: { response in
                print(response)
            }, onError: { error in
                print(error)
            }).disposed(by: rxbag)
    }
}

