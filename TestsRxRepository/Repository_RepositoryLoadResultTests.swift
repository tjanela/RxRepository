//
//  Repository_RepositoryTests.swift
//  Repository
//
//  Created by Tiago Janela on 1/30/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation

import XCTest

@testable import Repository

class Repository_RepositoryTests: XCTestCase {
    func testRepositoryLoadResult_equatable() {
        XCTAssertFalse(RepositoryLoadResult<String>.noValue == RepositoryLoadResult<String>.noValueDueToPolicy)
    }
}
