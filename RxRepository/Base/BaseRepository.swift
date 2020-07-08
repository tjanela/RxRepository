//
//  BaseRepository.swift
//  Repository
//
//  Created by Tiago Janela on 1/30/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation

import RxSwift

open class BaseRepository<T: Hashable, R: Request>: RepositoryProtocol {
    public typealias T = T
    public typealias R = R

    public func load(cachePolicy: CachePolicy, request: BaseRepository.R) -> Observable<RepositoryLoadResult<BaseRepository.T>> {
        fatalError("Subclasses must implement")
    }

    public func save(request: R, object: T) -> Completable {
        fatalError("Subclasses must implement")
    }

    public func clear() -> Completable {
        fatalError("Subclasses must implement")
    }
}
