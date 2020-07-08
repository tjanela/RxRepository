//
//  Repository_CompositeRepositoryTests.swift
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

enum RepositoryTestsRepositoryError: Error, Hashable {
    case general
}

class TestNetworkRepository<T: Hashable, R: Request>: NetworkRepository<T, R>{
    typealias LoadFromNetworkSignature = (R) -> Single<T>

    var loadFromNetworkImplementation: LoadFromNetworkSignature
    var loadFromNetworkInvocationCount = 0

    init(loadFromNetworkImplementation: @escaping LoadFromNetworkSignature, scheduler: SchedulerType) {
        self.loadFromNetworkImplementation = loadFromNetworkImplementation
        super.init(scheduler: scheduler)
    }

    override func loadFromNetwork(request: R) -> Single<T> {
        loadFromNetworkInvocationCount += 1
        return loadFromNetworkImplementation(request)
    }
}

struct TestCompositeRepositoryResult<T: Hashable, R: Request> {
    let memoryRepository: MemoryRepository<T, R>
    let diskCache: TestDiskCache<T, R>
    let diskRepository: DiskRepository<T, R>
    let networkRepository: TestNetworkRepository<T, R>
    let compositeRepository: CompositeRepository<T, R>
}

class Repository_CompositeRepositoryTests: XCTestCase {

    private func createCompositeRepository<T: Hashable, R: Hashable>(loadFromNetworkImplementation: @escaping (R) -> Single<T>,
                                                                     scheduler: SchedulerType)
        -> TestCompositeRepositoryResult<T, R> {
        let networkRepository = TestNetworkRepository(loadFromNetworkImplementation: loadFromNetworkImplementation,
                                                      scheduler: scheduler)
        let testCache = TestDiskCache<T, R>()
        let diskRepository = DiskRepository(diskCache: testCache)
        let memoryRepository = MemoryRepository<T, R>()
        let compositeRepository = CompositeRepository<T, R>(networkRepository: networkRepository,
                                                            diskRepository: diskRepository,
                                                            memoryRepository: memoryRepository,
                                                            scheduler: scheduler)
        return TestCompositeRepositoryResult(memoryRepository: memoryRepository,
                                             diskCache: testCache,
                                             diskRepository: diskRepository,
                                             networkRepository: networkRepository,
                                             compositeRepository: compositeRepository)
    }

    func testCompositeRepository_save() {
        let scheduler = TestScheduler(initialClock: 0)
        func loadFromNetworkImplementation(request: String) -> Single<String> {
            return Single.just(request)
        }

        let repositories = createCompositeRepository(loadFromNetworkImplementation: loadFromNetworkImplementation, scheduler: scheduler)
        let request = "save"
        let disposeBag = DisposeBag()

        let subject = repositories.compositeRepository.save(request: request, object: request)

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.completed(0)
            ]))

        expect(repositories.memoryRepository.memoryCache.cache[request]?.1).to(equal(request))
        expect(repositories.diskCache.cache[request]).to(equal(request))
    }

    func testCompositeRepositoryTests_reloadIgnoringCache_successNetworkResultSavedInAllCaches() {
        let scheduler = TestScheduler(initialClock: 0)
        func loadFromNetworkImplementation(request: String) -> Single<String> {
            return Single.just(request)
        }

        let repositories = createCompositeRepository(loadFromNetworkImplementation: loadFromNetworkImplementation, scheduler: scheduler)
        let request = "reloadIgnoringCache"
        let disposeBag = DisposeBag()

        let subject = repositories.compositeRepository.load(cachePolicy: .reloadIgnoringCache, request: request)

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(2, RepositoryLoadResult.value(request))
            ]))

        expect(repositories.networkRepository.loadFromNetworkInvocationCount).to(equal(1))
        expect(repositories.memoryRepository.memoryCache.cache[request]?.1).to(equal(request))
        expect(repositories.diskCache.cache[request]).to(equal(request))
    }

    func testCompositeRepositoryTests_returnCacheDontLoad_cachedInMemory() {
        let scheduler = TestScheduler(initialClock: 0)
        func loadFromNetworkImplementation(request: String) -> Single<String> {
            return Single.just(request)
        }

        let repositories = createCompositeRepository(loadFromNetworkImplementation: loadFromNetworkImplementation, scheduler: scheduler)
        let request = "returnCacheDontLoad"
        let disposeBag = DisposeBag()

        repositories.memoryRepository.memoryCache.cache[request] = (CacheEntry<Empty>(key: request,
                                                                                      expiresAt: Date().addingTimeInterval(5),
                                                                                      value: .empty), request)

        let subject = repositories.compositeRepository.load(cachePolicy: .returnCacheDontLoad, request: request)
        
        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(1, RepositoryLoadResult.value(request))
            ]))

        expect(repositories.networkRepository.loadFromNetworkInvocationCount).to(equal(0))
        expect(repositories.diskCache.loadInvocationCount).to(equal(0))
        expect(repositories.diskCache.saveInvocationCount).to(equal(0))
        expect(repositories.memoryRepository.memoryCache.cache[request]?.1).to(equal(request))
        expect(repositories.diskCache.cache[request]).to(beNil())
    }

    func testCompositeRepositoryTests_returnCacheDontLoad_cachedInDisk() {
        let scheduler = TestScheduler(initialClock: 0)
        func loadFromNetworkImplementation(request: String) -> Single<String> {
            return Single.just(request)
        }

        let repositories = createCompositeRepository(loadFromNetworkImplementation: loadFromNetworkImplementation, scheduler: scheduler)
        let request = "returnCacheDontLoad"
        let disposeBag = DisposeBag()

        repositories.diskCache.cache[request] = request

        let subject = repositories.compositeRepository.load(cachePolicy: .returnCacheDontLoad, request: request)

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(1, RepositoryLoadResult.value(request))
            ]))

        expect(repositories.networkRepository.loadFromNetworkInvocationCount).to(equal(0))
        expect(repositories.diskCache.loadInvocationCount).to(equal(1))
        expect(repositories.diskCache.saveInvocationCount).to(equal(0))
        expect(repositories.memoryRepository.memoryCache.cache[request]?.1).to(equal(request))
    }

    func testCompositeRepositoryTests_returnCacheDontLoad_notCached() {
        let scheduler = TestScheduler(initialClock: 0)
        func loadFromNetworkImplementation(request: String) -> Single<String> {
            return Single.just(request)
        }

        let repositories = createCompositeRepository(loadFromNetworkImplementation: loadFromNetworkImplementation, scheduler: scheduler)
        let request = "returnCacheDontLoad"
        let disposeBag = DisposeBag()

        let subject = repositories.compositeRepository.load(cachePolicy: .returnCacheDontLoad, request: request)

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(1, RepositoryLoadResult.noValueDueToPolicy)
            ]))

        expect(repositories.networkRepository.loadFromNetworkInvocationCount).to(equal(0))
        expect(repositories.diskCache.loadInvocationCount).to(equal(1))
        expect(repositories.diskCache.saveInvocationCount).to(equal(0))
    }

    func testCompositeRepositoryTests_returnCacheElseLoad_notCached() {
        let scheduler = TestScheduler(initialClock: 0)
        func loadFromNetworkImplementation(request: String) -> Single<String> {
            return Single.just(request)
        }

        let repositories = createCompositeRepository(loadFromNetworkImplementation: loadFromNetworkImplementation, scheduler: scheduler)
        let request = "returnCacheElseLoad"
        let disposeBag = DisposeBag()

        let subject = repositories.compositeRepository.load(cachePolicy: .returnCacheElseLoad, request: request)

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(3, RepositoryLoadResult.value(request))
            ]))

        expect(repositories.networkRepository.loadFromNetworkInvocationCount).to(equal(1))
        expect(repositories.diskCache.loadInvocationCount).to(equal(1))
        expect(repositories.diskCache.saveInvocationCount).to(equal(1))
        expect(repositories.memoryRepository.memoryCache.cache[request]?.1).to(equal(request))
    }

    func testCompositeRepositoryTests_returnCacheElseLoad_networkError() {
        let scheduler = TestScheduler(initialClock: 0)
        func loadFromNetworkImplementation(request: String) -> Single<String> {
            return Single.error(RepositoryTestsRepositoryError.general)
        }

        let repositories = createCompositeRepository(loadFromNetworkImplementation: loadFromNetworkImplementation, scheduler: scheduler)
        let request = "returnCacheElseLoad"
        let disposeBag = DisposeBag()

        let subject = repositories.compositeRepository.load(cachePolicy: .returnCacheElseLoad, request: request)

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(3, RepositoryLoadResult.error(RepositoryTestsRepositoryError.general))
            ]))

        expect(repositories.networkRepository.loadFromNetworkInvocationCount).to(equal(1))
        expect(repositories.diskCache.loadInvocationCount).to(equal(1))
        expect(repositories.diskCache.saveInvocationCount).to(equal(0))
        expect(repositories.memoryRepository.memoryCache.cache[request]).to(beNil())
    }

    func testCompositeRepositoryTests_returnCacheElseLoad_2times() {
        let scheduler = TestScheduler(initialClock: 0)
        func loadFromNetworkImplementation(request: String) -> Single<String> {
            return Single.just(request)
        }

        let repositories = createCompositeRepository(loadFromNetworkImplementation: loadFromNetworkImplementation, scheduler: scheduler)
        let request = "returnCacheElseLoad"
        let disposeBag = DisposeBag()

        let subject = repositories.compositeRepository.load(cachePolicy: .returnCacheElseLoad, request: request)

        expect(subject)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(3, RepositoryLoadResult.value(request))
            ]))

        expect(repositories.networkRepository.loadFromNetworkInvocationCount).to(equal(1))
        expect(repositories.diskCache.loadInvocationCount).to(equal(1))
        expect(repositories.diskCache.saveInvocationCount).to(equal(1))
        expect(repositories.memoryRepository.memoryCache.cache[request]?.1).to(equal(request))

        let subject2 = repositories.compositeRepository.load(cachePolicy: .returnCacheElseLoad, request: request)

        expect(subject2)
            .events(scheduler: scheduler, disposeBag: disposeBag)
            .to(equal([
                Recorded.next(6, RepositoryLoadResult.value(request))
            ]))
    }
}
