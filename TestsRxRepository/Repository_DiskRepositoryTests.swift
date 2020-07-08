//
//  Repository_DiskRepositoryTests.swift
//  RepositoryTests
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

class TestDiskCache<T: Hashable, R: Hashable>: BaseCache<T, R> {

    var cache: [R: T] = [:]
    var loadInvocationCount = 0
    var saveInvocationCount = 0

    override func load(request: R) -> T? {
        loadInvocationCount += 1
        return cache[request]
    }

    override func save(request: R, object: T?) {
        saveInvocationCount += 1
        cache[request] = object
    }

    override func clear() {
        cache.removeAll()
    }
}

class Repository_DiskRepositoryTests: XCTestCase {

    func testDiskRepository_noValue() {
        let scheduler = TestScheduler(initialClock: 0)
        let diskCache = TestDiskCache<String, String>()
        let sut = DiskRepository(diskCache: diskCache)
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

    func testDiskRepository_save() {
        let scheduler = TestScheduler(initialClock: 0)
        let diskCache = TestDiskCache<String, String>()
        let sut = DiskRepository(diskCache: diskCache)
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

    func testDiskRepository_reloadIgnoringCache() {
        let scheduler = TestScheduler(initialClock: 0)
        let diskCache = TestDiskCache<String, String>()
        let sut = DiskRepository(diskCache: diskCache)
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

    func testDiskRepository_returnCacheDontLoad() {
        let scheduler = TestScheduler(initialClock: 0)
        let diskCache = TestDiskCache<String, String>()
        let sut = DiskRepository(diskCache: diskCache)
        let disposeBag = DisposeBag()
        let request = "returnCacheDontLoad"

        diskCache.cache[request] = request

        let subject = sut
            .load(cachePolicy: .returnCacheDontLoad, request: request)

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(0, RepositoryLoadResult.value(request)),
                Recorded.completed(0)
            ]))
    }

    func testDiskRepository_returnCacheElseLoad() {
        let scheduler = TestScheduler(initialClock: 0)
        let diskCache = TestDiskCache<String, String>()
        let sut = DiskRepository(diskCache: diskCache)
        let disposeBag = DisposeBag()
        let request = "returnCacheElseLoad"

        diskCache.cache[request] = request

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
