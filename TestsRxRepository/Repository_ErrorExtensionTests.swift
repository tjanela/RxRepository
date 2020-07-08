//
//  Repository_ErrorExtensionTests.swift
//  RepositoryTests
//
//  Created by Tiago Janela on 2/3/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation
import XCTest

import Nimble

enum ErrorExtensionTestError: Error {
    case simpleCase1Error
    case simpleCase2Error
    case associatedValueCaseError(any: Any)
}

typealias ETR = ErrorExtensionTestError

@testable import Repository

class Repository_ErrorExtensionTests: XCTestCase {
    func testErrorExtension_areEqual() {
        expect(areEqual(ETR.simpleCase1Error, ETR.simpleCase1Error)).to(beTrue())
        expect(areEqual(ETR.simpleCase1Error, ETR.simpleCase2Error)).to(beFalse())
        expect(areEqual(ETR.associatedValueCaseError(any: "1"), ETR.associatedValueCaseError(any: "1"))).to(beTrue())
        expect(areEqual(ETR.associatedValueCaseError(any: "1"), ETR.associatedValueCaseError(any: "2"))).to(beFalse())

        expect(ETR.simpleCase1Error.isEqual(to: ETR.simpleCase1Error)).to(beTrue())
        expect(ETR.simpleCase1Error.isEqual(to: ETR.simpleCase2Error)).to(beFalse())
        expect(ETR.associatedValueCaseError(any: "1").isEqual(to: ETR.associatedValueCaseError(any: "1"))).to(beTrue())
        expect(ETR.associatedValueCaseError(any: "1").isEqual(to: ETR.associatedValueCaseError(any: "2"))).to(beFalse())

        let e1_1 = NSError(domain: "1", code: 1, userInfo: [:])
        let e1_2 = NSError(domain: "1", code: 1, userInfo: [:])
        let e2_1 = NSError(domain: "1", code: 2, userInfo: [:])
        let e3_1 = NSError(domain: "1", code: 3, userInfo: ["a":"b"])
        let e3_2 = NSError(domain: "1", code: 3, userInfo: ["a":"b"])
        let e4_1 = NSError(domain: "1", code: 4, userInfo: ["a":"b"])
        let e4_2 = NSError(domain: "1", code: 4, userInfo: ["a":"c"])

        expect(e1_1.isEqual(to: e1_2)).to(beTrue())
        expect(e1_1.isEqual(to: e2_1)).to(beFalse())
        expect(e3_1.isEqual(to: e3_2)).to(beTrue())
        expect(e4_1.isEqual(to: e4_2)).to(beFalse())
    }
}
