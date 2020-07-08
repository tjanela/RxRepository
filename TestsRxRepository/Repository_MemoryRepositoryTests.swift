//
//  Repository_MemoryRepositoryTests.swift
//  Repository
//
//  Created by Tiago Janela on 2/1/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation
import XCTest

import Nimble
import RxSwift
import RxTest

@testable import Repository

class Repository_MemoryRepositoryTests: XCTestCase {
    func testMemoryRepository_noValue() {
        let scheduler = TestScheduler(initialClock: 0)
        let sut = MemoryRepository<String, String>()
        let disposeBag = DisposeBag()
        let request = "returnCacheDontLoad"

        let subject = sut
            .load(cachePolicy: .returnCacheDontLoad, request: request)

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(0, RepositoryLoadResult.noValue),
                Recorded.completed(0)
            ]))
    }

    func testMemoryRepository_save() {
        let scheduler = TestScheduler(initialClock: 0)
        let sut = MemoryRepository<String, String>()
        let disposeBag = DisposeBag()
        let request = "save"

        let saveSubject = sut
            .save(request: request, object: request)

        expect(saveSubject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.completed(0)
            ]))

        let loadSubject = sut
            .load(cachePolicy: .returnCacheDontLoad, request: request)

        expect(loadSubject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(0, RepositoryLoadResult.value(request)),
                Recorded.completed(0)
            ]))
    }

    func testMemoryRepository_reloadIgnoringCache() {
        let scheduler = TestScheduler(initialClock: 0)
        let sut = MemoryRepository<String, String>()
        let disposeBag = DisposeBag()
        let request = "reloadIgnoringCache"

        let subject = sut
            .load(cachePolicy: .reloadIgnoringCache, request: request)

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(0, RepositoryLoadResult.noValueDueToPolicy),
                Recorded.completed(0)
            ]))
    }

    func testMemoryRepository_returnCacheDontLoad() {
        let scheduler = TestScheduler(initialClock: 0)
        let sut = MemoryRepository<String, String>()
        let disposeBag = DisposeBag()
        let request = "returnCacheDontLoad"

        sut.memoryCache.cache[request] = (CacheEntry<Empty>(key: request,
                                                            expiresAt: Date().addingTimeInterval(5),
                                                            value: .empty), request)

        let subject = sut
            .load(cachePolicy: .returnCacheDontLoad, request: request)

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(0, RepositoryLoadResult.value(request)),
                Recorded.completed(0)
            ]))
    }

    func testMemoryRepository_returnCacheElseLoad() {
        let scheduler = TestScheduler(initialClock: 0)
        let sut = MemoryRepository<String, String>()
        let disposeBag = DisposeBag()
        let request = "returnCacheElseLoad"

        sut.memoryCache.cache[request] = (CacheEntry<Empty>(key: request,
                                                            expiresAt: Date().addingTimeInterval(5),
                                                            value: .empty), request)

        let subject = sut
            .load(cachePolicy: .returnCacheElseLoad, request: request)

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(0, RepositoryLoadResult.value(request)),
                Recorded.completed(0)
            ]))
    }
}
