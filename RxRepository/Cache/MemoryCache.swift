//
//  MemoryCache.swift
//  Repository
//
//  Created by Tiago Janela on 2/6/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation

enum Empty: Int, Codable {
    case empty
}

public class MemoryCache<T, R: Hashable>: BaseCache<T, R> {

    var cache: [R: (CacheEntry<Empty>, T)] = [:]
    let cacheTTL: TimeInterval
    let lock = CacheLock()

    public init(cacheTTL: TimeInterval = 60) {
        self.cacheTTL = cacheTTL
    }

    public override func load(request: R) -> T? {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }
        guard let cacheEntry = cache[request] else {
            return nil
        }
        if cacheEntry.0.isExpired {
            return nil
        }
        return cacheEntry.1
    }

    public override func save(request: R, object: T?) {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }
        guard let object = object else {
            cache[request] = nil
            return
        }
        let cacheEntry = CacheEntry<Empty>(key: "\(T.self)", expiresAt: cacheExpiresAt, value: .empty)
        cache[request] = (cacheEntry, object)
    }

    public override func clear() {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }
        cache.removeAll()
    }

    private var cacheExpiresAt: Date {
        return Date().addingTimeInterval(cacheTTL)
    }
}
