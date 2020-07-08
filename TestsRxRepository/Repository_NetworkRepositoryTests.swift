//
//  Repository_NetworkRepositoryTests.swift
//  Repository
//
//  Created by Tiago Janela on 1/31/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation
import XCTest

import Nimble
import RxSwift
import RxTest

@testable import Repository

class TestSuccessNetworkRepository: NetworkRepository<String, String> {
    var invocationCount = 0
    override func loadFromNetwork(request: String) -> Single<String> {
        invocationCount += 1
        return Single.just(request)
    }
}

class TestErrorNetworkRepository: NetworkRepository<String, String> {
    override func loadFromNetwork(request: String) -> Single<String> {
        return Single.error(RepositoryError.general)
    }
}

class Repository_NetworkRepositoryTests: XCTestCase {
    func testNetworkRepository_loadNetworkThrowsAssertion() {
        #if arch(x86_64)
        let scheduler = TestScheduler(initialClock: 0)
        let sut = NetworkRepository<String, String>(scheduler: scheduler)
        expect { _ = sut.loadFromNetwork(request: "") }.to(throwAssertion())
        #else
        #endif
    }

    func testSuccessNetworkRepository_reloadIgnoringCache() {
        let scheduler = TestScheduler(initialClock: 0)
        let sut = TestSuccessNetworkRepository(scheduler: scheduler)
        let disposeBag = DisposeBag()
        let request = "reloadIgnoringCache"

        let subject = sut
            .load(cachePolicy: .reloadIgnoringCache, request: request)

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(2, RepositoryLoadResult.value(request)),
                Recorded.completed(2)
            ]))
    }

    func testSuccessNetworkRepository_singleRequest() {
        let scheduler = TestScheduler(initialClock: 0)
        let sut = TestSuccessNetworkRepository(scheduler: scheduler)
        let disposeBag = DisposeBag()
        let request = "reloadIgnoringCache"

        let s1 = sut.load(cachePolicy: .reloadIgnoringCache, request: request)
        let s2 = sut.load(cachePolicy: .reloadIgnoringCache, request: request)

        expect(sut.invocationCount).to(equal(1))

        expect(s1)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(2, RepositoryLoadResult.value(request)),
                Recorded.completed(2)
            ]))

        expect(s2)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(3, RepositoryLoadResult.value(request)),
                Recorded.completed(3)
            ]))
    }

    func testSuccessNetworkRepository_returnCacheElseLoad() {
        let scheduler = TestScheduler(initialClock: 0)
        let sut = TestSuccessNetworkRepository(scheduler: scheduler)
        let disposeBag = DisposeBag()
        let request = "returnCacheElseLoad"

        let subject = sut
            .load(cachePolicy: .returnCacheElseLoad, request: request)

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(2, RepositoryLoadResult.value(request)),
                Recorded.completed(2)
            ]))
    }

    func testSuccessNetworkRepository_returnCacheDontLoad() {
        let scheduler = TestScheduler(initialClock: 0)
        let sut = TestSuccessNetworkRepository(scheduler: scheduler)
        let disposeBag = DisposeBag()
        let request = "returnCacheDontLoad"

        let subject = sut
            .load(cachePolicy: .returnCacheDontLoad, request: request)

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(0, RepositoryLoadResult.noValueDueToPolicy),
                Recorded.completed(0)
            ]))
    }

    func testErrorNetworkRepository() {
        let scheduler = TestScheduler(initialClock: 0)
        let sut = TestErrorNetworkRepository(scheduler: scheduler)
        let disposeBag = DisposeBag()
        let request = "reloadIgnoringCache"

        let subject = sut
            .load(cachePolicy: .reloadIgnoringCache, request: request)

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(2, RepositoryLoadResult.error(RepositoryError.general)),
                Recorded.completed(2)
            ]))
    }

    func testNetworkRepository_save() {
        let scheduler = TestScheduler(initialClock: 0)
        let sut = TestSuccessNetworkRepository(scheduler: scheduler)
        let disposeBag = DisposeBag()
        let request = "reloadIgnoringCache"

        let subject = sut
            .save(request: request, object: "request")

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.completed(0)
            ]))
    }
}
