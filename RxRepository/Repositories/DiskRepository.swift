//
//  DiskRepository.swift
//  Repository
//
//  Created by Tiago Janela on 1/30/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation

import RxSwift

public class DiskRepository<T: Hashable, R: Request>: BaseRepository<T, R> {
    var diskCache: BaseCache<T, R>

    public init(diskCache: BaseCache<T, R>) {
        self.diskCache = diskCache
    }

    public override func load(cachePolicy: CachePolicy, request: R) -> Observable<RepositoryLoadResult<T>> {
        Observable.deferred { [weak self] () -> Observable<RepositoryLoadResult<T>> in
            guard let self = self else { throw RxError.unknown }
            switch cachePolicy {
            case .reloadIgnoringCache:
                return Observable.just(.noValueDueToPolicy)
            default:
                break
            }

            let result = self.diskCache.load(request: request)

            guard let unwrappedResult = result else {
                return Observable.just(.noValue)
            }

            return Observable.just(.value(unwrappedResult))
        }
    }

    public override func save(request: R, object: T) -> Completable {
        diskCache.save(request: request, object: object)
        return Completable.empty()
    }

    public override func clear() -> Completable {
        diskCache.clear()
        return Completable.empty()
    }
}
