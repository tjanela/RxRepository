//
//  CompositeRepository.swift
//  Repository
//
//  Created by Tiago Janela on 1/30/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation

import RxSwift

public class CompositeRepository<T: Hashable, R: Request>: BaseRepository<T, R> {

    let scheduler: SchedulerType

    let memoryRepository: BaseRepository<T, R>
    let diskRepository: BaseRepository<T, R>
    let networkRepository: BaseRepository<T, R>

    var subjects: [R: PublishSubject<RepositoryLoadResult<T>>] = [:]

    let disposeBag = DisposeBag()

    enum ResultProvenance {
        case fromMemory
        case fromDisk
        case fromNetwork
    }
    typealias LoadResult = (resultProvenance: ResultProvenance, result: RepositoryLoadResult<T>)

    public init(networkRepository: BaseRepository<T, R>,
                diskRepository: BaseRepository<T, R>,
                memoryRepository: BaseRepository<T, R>,
                scheduler: SchedulerType) {
        self.memoryRepository = memoryRepository
        self.diskRepository = diskRepository
        self.networkRepository = networkRepository
        self.scheduler = scheduler
    }

    public override func load(cachePolicy: CachePolicy, request: R) -> Observable<RepositoryLoadResult<T>> {
        Observable.deferred { [weak self] () -> Observable<RepositoryLoadResult<T>> in
            guard let self = self else { throw RxError.unknown }
            if self.subjects[request] == nil {
                self.subjects[request] = PublishSubject<RepositoryLoadResult<T>>()
            }

            guard let subject = self.subjects[request] else {
                return Observable.error(RepositoryError.general)
            }

            var loadResult: Observable<LoadResult> = Observable.empty()
            switch cachePolicy {
            case .reloadIgnoringCache:
                loadResult = self.networkLoad(cachePolicy: cachePolicy, request: request)
            case .returnCacheDontLoad:
                loadResult = self.cacheLoad(cachePolicy: cachePolicy, request: request)
            case .returnCacheElseLoad:
                loadResult = self.cacheLoad(cachePolicy: cachePolicy, request: request)
            }

            loadResult
                .do(onNext: { (result) in
                    subject.onNext(result.1)
                }, onError: { (error) in
                    subject.onNext(.error(error))
                })
                .subscribeOn(self.scheduler)
                .observeOn(self.scheduler)
                .subscribe()
                .disposed(by: self.disposeBag)

            return subject.asObservable()
        }
    }

    public override func save(request: R, object: T) -> Completable {
        return memoryRepository.save(request: request, object: object)
            .andThen(diskRepository.save(request: request, object: object))
            .andThen(networkRepository.save(request: request, object: object))
    }

    public func save(request: R, object: T, emit: Bool) -> Completable {
        if subjects[request] == nil {
            subjects[request] = PublishSubject<RepositoryLoadResult<T>>()
        }

        guard let subject = subjects[request] else {
            return Completable.error(RepositoryError.general)
        }
        return save(request: request, object: object)
            .do(onCompleted: {
                if !emit { return }
                subject.onNext(.value(object))
            })
    }

    public override func clear() -> Completable {
        return memoryRepository.clear()
            .andThen(diskRepository.clear())
    }

    private func networkLoad(cachePolicy: CachePolicy, request: R) -> Observable<LoadResult> {
        return networkRepository.load(cachePolicy: cachePolicy, request: request)
            .map { LoadResult(resultProvenance: .fromNetwork, result: $0) }
            .flatMap({ [memoryRepository, diskRepository, disposeBag, scheduler] (result) -> Observable<LoadResult> in
                switch result.1 {
                case .noValue:
                    fatalError("Should have a value at this point")
                case .noValueDueToPolicy:
                    fatalError("Unexpected cache policy")
                case .value(let value):
                    switch result.0 {
                    case .fromNetwork:
                        diskRepository.save(request: request, object: value)
                            .subscribeOn(scheduler)
                            .observeOn(scheduler)
                            .subscribe()
                            .disposed(by: disposeBag)
                        memoryRepository.save(request: request, object: value)
                            .subscribeOn(scheduler)
                            .observeOn(scheduler)
                            .subscribe()
                            .disposed(by: disposeBag)
                    default:
                        break
                    }
                default:
                    break
                }
                return Observable.just(result)
            })
    }

    private func cacheLoad(cachePolicy: CachePolicy, request: R) -> Observable<LoadResult> {
        return memoryRepository.load(cachePolicy: cachePolicy, request: request)
            .map { LoadResult(resultProvenance: .fromMemory, result: $0) }
            .flatMap({ [diskRepository] (result) -> Observable<LoadResult> in
                switch result.1 {
                case .noValue:
                    // If not on memory, try the disk, and save to memory
                    return diskRepository.load(cachePolicy: cachePolicy, request: request)
                        .map { LoadResult(resultProvenance: .fromDisk, result: $0) }
                case .noValueDueToPolicy:
                    fatalError("Unexpected cache policy")
                default:
                    break
                }
                return Observable.just(result)
            })
            .flatMap({ [networkRepository, memoryRepository, disposeBag] (result) -> Observable<LoadResult> in
                switch result.1 {
                case .noValue:
                    // If not on disk, try the network and save to disk and memory
                    return networkRepository.load(cachePolicy: cachePolicy, request: request)
                        .map { LoadResult(resultProvenance: .fromNetwork, result: $0) }
                case .noValueDueToPolicy:
                    fatalError("Unexpected cache policy")
                case .value(let value):
                    switch result.0 {
                    case .fromDisk:
                        memoryRepository.save(request: request, object: value)
                            .subscribe()
                            .disposed(by: disposeBag)
                    default:
                        break
                    }
                default:
                    break
                }
                return Observable.just(result)
            })
            .flatMap({ [memoryRepository, diskRepository, disposeBag, scheduler] (result) -> Observable<LoadResult> in
                switch result.1 {
                case .noValue:
                    fatalError("Should have a value at this point")
                case .noValueDueToPolicy:
                    break
                case .value(let value):
                    switch result.0 {
                    case .fromNetwork:
                        diskRepository.save(request: request, object: value)
                            .subscribeOn(scheduler)
                            .observeOn(scheduler)
                            .subscribe()
                            .disposed(by: disposeBag)
                        memoryRepository.save(request: request, object: value)
                            .subscribeOn(scheduler)
                            .observeOn(scheduler)
                            .subscribe()
                            .disposed(by: disposeBag)
                    default:
                        break
                    }
                default:
                    break
                }
                return Observable.just(result)
            })
    }
}
