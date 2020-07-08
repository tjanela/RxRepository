//
//  Repository_CryptoStreamsTests.swift
//  Repository
//
//  Created by Tiago Janela on 4/16/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation
import XCTest
//
import CryptoSwift
import Nimble
import MonadicJSON
import RxSwift
import RxTest
//
import Extensions

@testable import Repository

class Repository_CryptoStreamsTests: XCTestCase {

    func cipher(_ k: Data, _ p: Data) -> Data {
        return Data(try! AES(key: k.bytes, blockMode: ECB(), padding: Padding.pkcs7).encrypt(p.bytes))
    }

    func testDiskCacheUtils_testInputStream() {
        let k = try! SecRandom.generate(bytes: 16)
        let p = try! SecRandom.generate(bytes: 20)
        let c = cipher(k, p)
        let i = CryptoInputStream(data: c, key: k)
        i.open()
        var d = Data()
        while i.hasBytesAvailable {
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            let read = i.read(buffer, maxLength: 1024)
            if read == 0 {
                break
            }
            if read == -1 {
                break
            }
            d.append(buffer, count: read)
        }
        expect(d).to(equal(p))
    }

    func testDiskCacheUtils_testOutputStream() {
        let k = try! SecRandom.generate(bytes: 16)
        let p = try! SecRandom.generate(bytes: 20)
        let c = cipher(k, p)
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCacheUtils_testOutputStream", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        let finalUrl = url.appendingPathComponent("test.data")
        let i = CryptoOutputStream(url: finalUrl, append: false, key: k)!
        i.open()
        _ = i.write(p.bytes, maxLength: p.count)
        i.close()
        let d = try! Data(contentsOf: finalUrl)

        expect(d).to(equal(c))
    }

    func testDiskCacheUtils_testJSONOutputStream() {
        let k = try! SecRandom.generate(bytes: 16)
        let array = generateBigArray(10, 501)
        let p = try! JSONSerialization.data(withJSONObject: array, options: [])
        let c = cipher(k, p)
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCacheUtils_testJSONOutputStream", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        let finalUrl = url.appendingPathComponent("test.data")
        let i = CryptoOutputStream(url: finalUrl, append: false, key: k)!
        i.open()
        _ = i.write(p.bytes, maxLength: p.count)
        i.close()
        let d = try! Data(contentsOf: finalUrl)

        expect(d).to(equal(c))
    }

    func testDiskCacheUtils_testJSONInputStream() {
        let k = try! SecRandom.generate(bytes: 16)
        let array = generateBigArray(10, 501)
        let p = try! JSONSerialization.data(withJSONObject: array, options: [])
        let c = cipher(k, p)
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCacheUtils_testJSONInputStream", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        let finalUrl = url.appendingPathComponent("test.data")
        try! c.write(to: finalUrl, options: [.atomicWrite])
        let i = CryptoInputStream(url: finalUrl, key: k)!
        i.open()
        defer { i.close() }
        let readArray = try? MonadicJSONDecoder().decode([String].self, from: i)

        expect(readArray).to(equal(array))
    }

    func testDiskCacheUtils_testJSONInputStream2() {
        let k = try! SecRandom.generate(bytes: 16)
        let array = generateBigArray(10, 500)
        let p = try! JSONSerialization.data(withJSONObject: array, options: [])
        let c = cipher(k, p)
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCacheUtils_testJSONInputStream2", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        let finalUrl = url.appendingPathComponent("test.data")
        try! c.write(to: finalUrl, options: [.atomicWrite])
        let i = CryptoInputStream(url: finalUrl, key: k)!
        i.open()
        defer { i.close() }
        let readArray = try? MonadicJSONDecoder().decode([String].self, from: i)
        expect(readArray).to(equal(array))
    }

    func testDiskCacheUtils_testJSONInputStream3() {
        let k = try! SecRandom.generate(bytes: 16)
        let value = [true]
        let p = try! JSONSerialization.data(withJSONObject: value, options: [])
        let c = cipher(k, p)
        guard let url = try? DiskCacheUtils.cacheFolder(object: "testDiskCacheUtils_testJSONInputStream", create: true) else {
            fail("Couldn't get URL for DiskCache")
            return
        }
        let finalUrl = url.appendingPathComponent("test.data")
        try! c.write(to: finalUrl, options: [.atomicWrite])
        let i = CryptoInputStream(url: finalUrl, key: k)!
        i.open()
        defer { i.close() }
        let readValue = try! MonadicJSONDecoder().decode([Bool].self, from: i)

        expect(readValue).to(equal(value))
    }
}
