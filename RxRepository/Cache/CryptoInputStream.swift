//
//  CryptoInputStream.swift
//  Repository
//
//  Created by Tiago Janela on 4/16/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//
import Foundation
//
import CryptoSwift

public class CryptoInputStream: InputStream {

    var underlyingStream: InputStream
    var cryptor: (Cryptor & Updatable)
    var keySize: Int
    var needsPadding: Bool = false
    var streamEnd = false

    public init(data: Data, key: Data) {
        underlyingStream = InputStream(data: data)
        keySize = key.count
        cryptor = (try? AES(key: key.bytes, blockMode: ECB(), padding: .pkcs7).makeDecryptor())!
        super.init(data: data)
    }

    public init?(url: URL, key: Data) {
        underlyingStream = InputStream(url: url)!
        keySize = key.count
        cryptor = (try? AES(key: key.bytes, blockMode: ECB(), padding: .pkcs7).makeDecryptor())!
        super.init(data: Data())
    }

    override public func open() {
        //super.open()
        underlyingStream.open()
    }

    public override func close() {
        //super.close()
        underlyingStream.close()
    }

    var internalBuffer = Data()

    private func readFromInternalBuffer(_ buffer: UnsafeMutablePointer<UInt8>, count: Int) {
        internalBuffer.withUnsafeBytes { (internalBufferPointer: UnsafeRawBufferPointer) -> Void in
            let internalBufferBound = internalBufferPointer.bindMemory(to: UInt8.self)
            buffer.initialize(from: internalBufferBound.baseAddress!, count: count)
        }
        internalBuffer = internalBuffer.dropFirst(count)
    }

    public override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        autoreleasepool { () -> Int in
            //fill buffer until there is len
            while internalBuffer.count < len && !streamEnd {
                let blockSize = keySize
                var data = Data()
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: blockSize)
                let read = underlyingStream.read(buffer, maxLength: blockSize)
                data.append(buffer, count: read)
                buffer.deallocate()
                if read < 0 {
                    return read
                }
                if read == 0 || read < blockSize {
                    streamEnd = true
                }
                var decrypted: [UInt8]
                if streamEnd {
                    decrypted = (try? cryptor.finish(withBytes: data.bytes))!
                } else {
                    decrypted = (try? cryptor.update(withBytes: data.bytes))!
                    needsPadding = true
                }
                if decrypted.count > 0 {
                    internalBuffer += decrypted
                }

                if streamEnd && needsPadding {
                    internalBuffer = Data(Padding.pkcs7.remove(from: internalBuffer.bytes, blockSize: blockSize))
                }
            }

            //if there are enough bytes in internal buffer return from the buffer
            if internalBuffer.count > 0 {
                let count = min(internalBuffer.count, len)
                readFromInternalBuffer(buffer, count: count)
                return count
            }

            return streamEnd ? 0 : -1
        }
    }

    public override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>,
                                   length len: UnsafeMutablePointer<Int>) -> Bool {
        return false
    }

    public override var hasBytesAvailable: Bool { true }

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
