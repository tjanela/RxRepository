//
//  DiskCache.swift
//  Repository
//
//  Created by Tiago Janela on 1/30/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//
import Foundation
//
import PMJSON
import MonadicJSON
//
import DevTools

public enum DiskCacheError: Error {
    case couldNotOpenStream
    case couldNotWriteJSON
}

public class DiskCache<T: Codable, R: Request>: BaseCache<T, R> {

    let cacheFolder: URL
    let cipherKey: Data
    let decoder = MonadicJSONDecoder()
    let encoder = PMJSON.JSON.Encoder()
    let cacheTTL: TimeInterval
    let lock = CacheLock()

    public init(cacheFolder: URL, cipherKey: Data = Data(), cacheTTL: TimeInterval = 60) {
        self.cacheFolder = cacheFolder
        if !cipherKey.isEmpty {
            let length = cipherKey.count
            let validLengths = [128, 192, 256].map { $0 / 8 }
            let validLengthsMessage = validLengths.map { "\($0)B" }.joined(separator: ", ")
            let assertMessage = "cipherKey provided to DiskCache is not valid. Length is \(length)B. Valid lengths are \(validLengthsMessage)"
            assert(validLengths.contains(length), assertMessage)
        }
        self.cipherKey = cipherKey
        self.cacheTTL = cacheTTL
        super.init()
    }

    public func inputStream(url: URL) -> InputStream? {
        if shouldCipher {
            return CryptoInputStream(url: url, key: cipherKey)
        }
        return InputStream(url: url)
    }

    public func outputStream(url: URL) -> OutputStream? {
        if shouldCipher {
            return CryptoOutputStream(url: url, append: false, key: cipherKey)
        }
        return OutputStream(url: url, append: false)
    }

    public override func load(request: R) -> T? {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }
        do {
            let url = filenameFor(type: T.self, request: request)
            guard let inputStream = inputStream(url: url) else {
                return nil
            }
            inputStream.open()
            defer {
                inputStream.close()
            }
            let diskCacheEntry = try decoder.decode(CacheEntry<T>.self, from: inputStream)
            if diskCacheEntry.expiresAt < Date() {
                return nil
            }
            let value = diskCacheEntry.value
            return value
        } catch {
            DevTools.Log.info("\(error.localizedDescription) | \(error)")
            return nil
        }
    }

    public override func save(request: R, object: T?) {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }
        let url = filenameFor(type: T.self, request: request)
        do {
            if object == nil {
                try? FileManager.default.removeItem(at: url)
                return
            }
            //Crashing
            let diskCacheEntry = CacheEntry(key: "\(T.self)",
                                            expiresAt: cacheExpiresAt,
                                            value: object)
            //Crashing
            guard let stream = outputStream(url: url) else {
                throw DiskCacheError.couldNotOpenStream
            }
            var error: NSError?
            stream.open()
            let json = try encoder.encodeAsJSON(diskCacheEntry).ns
            let result = JSONSerialization.writeJSONObject(json, to: stream, options: [], error: &error)
            stream.close()
            if result == 0 {
                throw DiskCacheError.couldNotWriteJSON
            }
        } catch {
            try? FileManager.default.removeItem(at: url)
            DevTools.Log.error("\(error.localizedDescription) | \(error)")
        }
    }

    public override func clear() {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }
        do {
            let filesUrls = try FileManager.default.contentsOfDirectory(at: cacheFolder,
                                                                        includingPropertiesForKeys: [],
                                                                        options: [])
            for fileUrl in filesUrls {
                try? FileManager.default.removeItem(at: fileUrl)
            }
        } catch {
            DevTools.Log.info("\(error.localizedDescription) | \(error)")
        }
    }

    private var shouldCipher: Bool {
        return !cipherKey.isEmpty
    }

    private var cacheExpiresAt: Date {
        return Date().addingTimeInterval(cacheTTL)
    }

    private func filenameFor(type: T.Type, request: R) -> URL {
        let filename = "Cache_\(type)_\(request.stringRepresentation).data"
        return cacheFolder
            .appendingPathComponent(filename)
    }
}

struct DiskCacheUtils {

    static func baseCacheFolder() throws -> URL {
        return try FileManager.default
            .url(for: .cachesDirectory,
                 in: .userDomainMask,
                 appropriateFor: nil,
                 create: true)
            .appendingPathComponent("DiskCache")
    }

    static func cacheFolder(object: String, create: Bool) throws -> URL {
        let url = try baseCacheFolder()
            .appendingPathComponent(object)
        try FileManager.default.createDirectory(at: url,
                                                withIntermediateDirectories: true,
                                                attributes: [:])
        return url
    }
}
