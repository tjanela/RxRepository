//
//  Repository_MemoryCacheTests.swift
//  Repository
//
//  Created by Tiago Janela on 2/6/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation
import XCTest

import Nimble
import RxSwift
import RxTest

@testable import Repository

class Repository_MemoryCacheTests: XCTestCase {
    func testMemoryCache_save() {
        let sut = MemoryCache<String, String>()
        let request = "save"

        expect(_ = sut.save(request: request, object: request)).toNot(throwError())
        expect(sut.cache[request]).toNot(beNil())
        expect(sut.cache[request]?.1).to(equal(request))
    }

    func testMemoryCache_load() {
        let sut = MemoryCache<String, String>()
        let request = "load"
        sut.cache[request] = (CacheEntry<Empty>(key: request,
                                                expiresAt: Date().addingTimeInterval(5),
                                                value: .empty), request)
        expect(sut.load(request: request)).to(equal(request))
    }

    func testMemoryCache_clear() {
        #if arch(x86_64)
        let sut = MemoryCache<String, String>()
        let request = "clear"
        sut.cache[request] = (CacheEntry<Empty>(key: request,
                                                expiresAt: Date().addingTimeInterval(5),
                                                value: .empty), request)
        expect(_ = sut.clear()).toNot(throwAssertion())
        expect(sut.cache.isEmpty).to(beTrue())
        #else
        #endif
    }
}
