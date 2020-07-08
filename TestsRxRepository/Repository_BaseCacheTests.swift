//
//  Repository_BaseCacheTests.swift
//  i9
//
//  Created by Tiago Janela on 2/3/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation
import XCTest

import Nimble
import RxSwift
import RxTest

@testable import Repository

class Repository_BaseCacheTests: XCTestCase {
    func testBaseCache_saveThrows() {
        #if arch(x86_64)
        let sut = BaseCache<String, String>()
        let request = "save"

        expect(_ = sut.save(request: request, object: request)).to(throwAssertion())
        #else
        #endif
    }

    func testBaseCache_loadThrows() {
        #if arch(x86_64)
        let sut = BaseCache<String, String>()
        let request = "save"

        expect(_ = sut.load(request: request)).to(throwAssertion())
        #else
        #endif
    }

    func testBaseCache_clearThrows() {
        #if arch(x86_64)
        let sut = BaseCache<String, String>()

        expect(_ = sut.clear()).to(throwAssertion())
        #else
        #endif
    }
}
