//
//  RepositoryV2Protocol.swift
//  Repository
//
//  Created by Tiago Janela on 1/30/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation

import RxSwift

public protocol RepositoryProtocol {
    associatedtype T: Hashable
    associatedtype R: Request
    func load(cachePolicy: CachePolicy, request: R) -> Observable<RepositoryLoadResult<T>>
    func save(request: R, object: T) -> Completable
    func clear() -> Completable
}
