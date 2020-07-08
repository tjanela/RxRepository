//
//  CryptoOutputStream.swift
//  Repository
//
//  Created by Tiago Janela on 4/16/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//
import Foundation
//
import CryptoSwift

public class CryptoOutputStream: OutputStream {

    let underlyingStream: OutputStream
    var cryptor: (Cryptor & Updatable)

    public override func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        let data = Data(bytes: buffer, count: len)
        guard let bytes = try? cryptor.update(withBytes: data.bytes) else {
            return -1
        }

        if bytes.count == 0 {
            return len
        }
        return bytes.withUnsafeBytes({ (innerBuffer: UnsafeRawBufferPointer) -> Int in
            let a = innerBuffer.bindMemory(to: UInt8.self)
            let result = underlyingStream.write(a.baseAddress!, maxLength: bytes.count)
            if result <= 0 {
                return result
            }
            return len
        })
    }

    public override func open() {
        underlyingStream.open()
    }

    public override func close() {
        defer {
            underlyingStream.close()
        }
        guard let bytes = try? cryptor.finish() else {
            return
        }
        bytes.withUnsafeBytes({ (innerBuffer: UnsafeRawBufferPointer) -> Void in
            let a = innerBuffer.bindMemory(to: UInt8.self)
            underlyingStream.write(a.baseAddress!, maxLength: bytes.count)
        })
    }

    public override var hasSpaceAvailable: Bool { true }

    public init(toMemory: (), key: Data) {
        self.underlyingStream = OutputStream(toMemory: ())
        self.cryptor = (try? AES(key: key.bytes, blockMode: ECB(), padding: .pkcs7).makeEncryptor())!
        super.init(toMemory: ())
    }

    public init(toBuffer buffer: UnsafeMutablePointer<UInt8>, capacity: Int, key: Data) {
        self.underlyingStream = OutputStream(toBuffer: buffer, capacity: capacity)
        self.cryptor = (try? AES(key: key.bytes, blockMode: ECB(), padding: .pkcs7).makeEncryptor())!
        super.init(toMemory: ())
    }

    public init?(url: URL, append shouldAppend: Bool, key: Data) {
        self.underlyingStream = OutputStream(url: url, append: shouldAppend)!
        self.cryptor = (try? AES(key: key.bytes, blockMode: ECB(), padding: .pkcs7).makeEncryptor())!
        super.init(toMemory: ())
    }
    public override var streamStatus: Stream.Status {
        underlyingStream.streamStatus
    }

    public override var streamError: Error? {
        underlyingStream.streamError
    }

    public override func property(forKey key: Stream.PropertyKey) -> Any? {
        underlyingStream.property(forKey: key)
    }

    public override func setProperty(_ property: Any?, forKey key: Stream.PropertyKey) -> Bool {
        underlyingStream.setProperty(property, forKey: key)
    }

    public override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        underlyingStream.schedule(in: aRunLoop, forMode: mode)
    }
    public override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        underlyingStream.remove(from: aRunLoop, forMode: mode)
    }
}
