//
//  Repository_BaseRepositoryTests.swift
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

class Repository_BaseRepositoryTests: XCTestCase {
    func testBaseRepository_saveThrows() {
        #if arch(x86_64)
        let sut = BaseRepository<String, String>()
        let request = "save"

        expect(_ = sut.save(request: request, object: request)).to(throwAssertion())
        #else
        #endif
    }

    func testBaseRepository_loadThrows() {
        #if arch(x86_64)
        let sut = BaseRepository<String, String>()
        let request = "save"

        expect(_ = sut.load(cachePolicy: .reloadIgnoringCache, request: request)).to(throwAssertion())
        #else
        #endif
    }
}
