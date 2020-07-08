//
//  Repository_DiskCacheTests.swift
//  i9
//
//  Created by Tiago Janela on 2/3/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation
import XCTest
//
import Nimble
import RxSwift
import RxTest
//
import Extensions

@testable import Repository

class Repository_DiskCacheTests: XCTestCase {

    override func tearDown() {
        if let url = try? DiskCacheUtils.baseCacheFolder() {
            try? FileManager.default.removeItem(at: url)
        }
        super.tearDown()
    }

    func testDiskCacheUtils_cacheFolder() {
        expect {
            try DiskCacheUtils.cacheFolder(object: "testDiskCacheUtils_cacheFolder", create: true)
        }
        .toNot(throwError())
    }

    func testDiskCache_saveNoCipher() {
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCache_saveNoCipher", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        let sut = DiskCache<String, String>(cacheFolder: url)
        expect(sut.save(request: "request", object: "object")).toNot(raiseException())
    }

    func testDiskCache_loadNoCipherNotExpired() {
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCache_loadNoCipherNotExpired", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        let sut = DiskCache<String, String>(cacheFolder: url)
        expect(sut.save(request: "request", object: "object")).toNot(raiseException())
        expect(sut.load(request: "request")).toNot(raiseException())
        expect(sut.load(request: "request")).toNot(beNil())
        expect(sut.load(request: "request")).to(equal("object"))
    }

    func testDiskCache_initInvalidKey() {
        #if arch(x86_64)
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCache_initInvalidKey", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        expect {
            _ = try DiskCache<String, String>(cacheFolder: url,cipherKey: SecRandom.generate(bytes: 2))
        }
        .to(throwAssertion())
        #else
        #endif
    }

    func testDiskCache_initValidKey() {
        #if arch(x86_64)
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCache_initValidKey", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        expect {
            _ = try DiskCache<String, String>(cacheFolder: url,cipherKey: SecRandom.generate(bytes: 16))
        }
        .toNot(throwAssertion())
        expect {
            _ = try DiskCache<String, String>(cacheFolder: url,cipherKey: SecRandom.generate(bytes: 24))
        }
        .toNot(throwAssertion())
        expect {
            _ = try DiskCache<String, String>(cacheFolder: url,cipherKey: SecRandom.generate(bytes: 32))
        }
        .toNot(throwAssertion())
        #else
        #endif
    }

    func testDiskCache_saveCipher() {
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCache_saveCipher", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        guard let sut = try? DiskCache<String, String>(cacheFolder: url, cipherKey: SecRandom.generate(bytes: 16)) else {
            fail("Couldn't create DiskCache")
            return
        }
        expect(sut.save(request: "request", object: "object")).toNot(raiseException())
    }

    func testDiskCache_loadCipherNotExpired() {
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCache_loadCipherNotExpired", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        guard let sut = try? DiskCache<String, String>(cacheFolder: url, cipherKey: SecRandom.generate(bytes: 16)) else {
            fail("Couldn't create DiskCache")
            return
        }
        expect(sut.save(request: "request", object: "object")).toNot(raiseException())
        expect(sut.load(request: "request")).toNot(raiseException())
        expect(sut.load(request: "request")).toNot(beNil())
        expect(sut.load(request: "request")).to(equal("object"))
    }

    func testDiskCache_clear() {
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCache_clear", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        let sut = DiskCache<String, String>(cacheFolder: url)
        
        expect(sut.save(request: "request", object: "object")).toNot(raiseException())
        expect(try? FileManager.default.contentsOfDirectory(at: url,
                                                            includingPropertiesForKeys: [],
                                                            options: [])).toNot(equal([]))
        expect(sut.clear()).toNot(raiseException())
        expect(try? FileManager.default.contentsOfDirectory(at: url,
                                                       includingPropertiesForKeys: [],
            options: [])).to(equal([]))
    }

    func testDiskCache_largeObject_noCipher() {
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCache_largeObject_noCipher", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        let sut = DiskCache<[String], String>(cacheFolder: url)

        let object = generateBigArray(10, 501)

        expect(sut.save(request: "request", object: object)).toNot(raiseException())
        expect(try? FileManager.default.contentsOfDirectory(at: url,
                                                            includingPropertiesForKeys: [],
                                                            options: [])).toNot(equal([]))
        expect(sut.load(request: "request")).toNot(raiseException())
        expect(sut.load(request: "request") == object).to(beTrue())
        expect(sut.clear()).toNot(raiseException())
        expect(try? FileManager.default.contentsOfDirectory(at: url,
                                                            includingPropertiesForKeys: [],
                                                            options: [])).to(equal([]))
    }

    func testDiskCache_extraLargeObject_noCipher() {
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCache_extraLargeObject_noCipher", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        let sut = DiskCache<[String: String], String>(cacheFolder: url, cacheTTL: 60 * 60)

        let object = generateBigDictionary(1024, 5 * 1024)
        expect(sut.save(request: "request", object: object)).toNot(raiseException())
        expect(try? FileManager.default.contentsOfDirectory(at: url,
                                                            includingPropertiesForKeys: [],
                                                            options: [])).toNot(equal([]))
        var loadedObject: [String: String]?
        expect({ loadedObject = sut.load(request: "request") }()).toNot(raiseException())
        expect(loadedObject == object).to(beTrue())
        expect(sut.clear()).toNot(raiseException())
        expect(try? FileManager.default.contentsOfDirectory(at: url,
                                                            includingPropertiesForKeys: [],
                                                            options: [])).to(equal([]))
    }

    func testDiskCache_largeObject_cipher() {
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCache_largeObject_cipher", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        let sut = DiskCache<[String], String>(cacheFolder: url, cipherKey: (try? SecRandom.generate(bytes: 16))!)

        let object = generateBigArray(10, 501)

        expect(sut.save(request: "request", object: object)).toNot(raiseException())
        expect(try? FileManager.default.contentsOfDirectory(at: url,
                                                            includingPropertiesForKeys: [],
                                                            options: [])).toNot(equal([]))
        expect(sut.load(request: "request")).toNot(raiseException())
        expect(sut.load(request: "request") == object).to(beTrue())
        expect(sut.clear()).toNot(raiseException())
        expect(try? FileManager.default.contentsOfDirectory(at: url,
                                                            includingPropertiesForKeys: [],
                                                            options: [])).to(equal([]))
    }

    func testDiskCache_extraLargeObject_cipher() {
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCache_extraLargeObject_cipher", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        let sut = DiskCache<[String: String], String>(cacheFolder: url, cipherKey: (try? SecRandom.generate(bytes: 16))!, cacheTTL: 60 * 60)

        let object = generateBigDictionary(1024, 5 * 1024)
        expect(sut.save(request: "request", object: object)).toNot(raiseException())
        expect(try? FileManager.default.contentsOfDirectory(at: url,
                                                            includingPropertiesForKeys: [],
                                                            options: [])).toNot(equal([]))
        var loadedObject: [String: String]?
        expect({ loadedObject = sut.load(request: "request") }()).toNot(raiseException())
        expect(loadedObject == object).to(beTrue())
        expect(sut.clear()).toNot(raiseException())
        expect(try? FileManager.default.contentsOfDirectory(at: url,
                                                            includingPropertiesForKeys: [],
                                                            options: [])).to(equal([]))
    }

    func testDiskCache_codableWithDecimal() {
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCache_codableWithDecimal_noCipher", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        struct ACodableWithDecimal: Codable, Hashable {
            let decimal: Decimal
        }
        let sut = DiskCache<ACodableWithDecimal, String>(cacheFolder: url)

        let n = NumberFormatter()
        n.maximumFractionDigits = 2
        n.minimumFractionDigits = 2
        for i in 0...10000 {
            let d = Double(i) / 100.0
            let ds = n.string(for: d)!
            let object = ACodableWithDecimal(decimal: Decimal(string: ds)!)
            expect(sut.save(request: "request", object: object)).toNot(raiseException())
            expect(try? FileManager.default.contentsOfDirectory(at: url,
                                                                includingPropertiesForKeys: [],
                                                                options: [])).toNot(equal([]))
            let loadedObject = sut.load(request: "request")
            expect(loadedObject).to(equal(object))
            expect(n.string(for: loadedObject?.decimal)).to(equal("\(ds)"))
            expect(sut.clear()).toNot(raiseException())
            expect(try? FileManager.default.contentsOfDirectory(at: url,
                                                                includingPropertiesForKeys: [],
                                                                options: [])).to(equal([]))
        }
    }
}

func generateBigDictionary(_ count: Int, _ sizePerEntry: Int) -> [String: String] {
    var result: [String: String] = [:]
    let entry = String.random(ofLength: sizePerEntry)
    for i in 0..<count {
        result["\(i)"] = String(entry)
    }

    return result
}

func generateBigArray(_ count: Int, _ sizePerEntry: Int) -> [String] {
    var result: [String] = []
    let entry = String.random(ofLength: sizePerEntry)
    for _ in 0..<count {
        result.append(String(entry))
    }

    return result
}
