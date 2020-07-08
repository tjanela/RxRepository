//
//  NetworkRepository.swift
//  Repository
//
//  Created by Tiago Janela on 1/30/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation

import RxSwift

open class NetworkRepository<T: Hashable, R: Request>: BaseRepository<T, R> {

    var subjects: [R: ReplaySubject<T>] = [:]
    let disposeBag = DisposeBag()
    let scheduler: SchedulerType
    public init(scheduler: SchedulerType) {
        self.scheduler = scheduler
    }

    public override func load(cachePolicy: CachePolicy,
                              request: R) -> Observable<RepositoryLoadResult<T>> {
        switch cachePolicy {
        case .reloadIgnoringCache,
             //If this repository is invoked with this value then we should load
             .returnCacheElseLoad:
            if let subject = subjects[request] {
                return subject
                    .map { RepositoryLoadResult.value($0) }
                    .asObservable()
            }

            let p = ReplaySubject<T>.create(bufferSize: 1)
            subjects[request] = p

            loadFromNetwork(request: request)
                .subscribeOn(scheduler)
                .observeOn(scheduler)
                .do(onSuccess: { [weak self] (result) in
                    p.onNext(result)
                    p.onCompleted()
                    self?.subjects[request] = nil
                }, onError: { [weak self] error in
                    p.onError(error)
                    self?.subjects[request] = nil
                })
                .subscribe()
                .disposed(by: disposeBag)

            return p
                .map { RepositoryLoadResult.value($0) }
                .catchError { Observable.just(RepositoryLoadResult.error($0)) }
                .asObservable()
        case .returnCacheDontLoad:
            return Observable.just(.noValueDueToPolicy)
        }
    }

    open func loadFromNetwork(request: NetworkRepository.R) -> Single<NetworkRepository.T> {
        fatalError("Subclasses must implement")
    }

    public override func save(request: R, object: T) -> Completable {
        return Completable.empty()
    }

    public override func clear() -> Completable {
        return Completable.empty()
    }
}
