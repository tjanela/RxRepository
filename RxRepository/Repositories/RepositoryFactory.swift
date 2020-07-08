//
//  RepositoryFactory.swift
//  Repository
//
//  Created by Tiago Janela on 2/3/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//
import Foundation
//
import RxSwift

public struct RepositoryFactory {
    public static func createCacheRepository<T: Codable, R: Hashable>(for object: String,
                                                                      cipherKey: Data = Data(),
                                                                      cacheTTL: TimeInterval = defaultCacheTTL) -> BaseRepository<T, R> {
        let memoryRepository = MemoryRepository<T, R>(cacheTTL: cacheTTL)
        do {
            let cacheFolder = try DiskCacheUtils.cacheFolder(object: object,
                                                             create: true)
            let diskCache = DiskCache<T, R>(cacheFolder: cacheFolder,
                                            cipherKey: cipherKey,
                                            cacheTTL: cacheTTL)
            return DiskRepository<T, R>(diskCache: diskCache)
        } catch {
            return memoryRepository
        }
    }

    public static func createCompositeRepository<T: Codable, R: Hashable>(for object: String,
                                                                          networkRepository: BaseRepository<T, R>,
                                                                          scheduler: SchedulerType,
                                                                          cipherKey: Data = Data(),
                                                                          cacheTTL: TimeInterval = defaultCacheTTL) -> CompositeRepository<T, R> {
        let memoryRepository: BaseRepository<T, R> = MemoryRepository(cacheTTL: cacheTTL)

        let diskRepository: BaseRepository<T, R> = createCacheRepository(for: object,
                                                                                      cipherKey: cipherKey,
                                                                                      cacheTTL: cacheTTL)

        return CompositeRepository(networkRepository: networkRepository,
                                              diskRepository: diskRepository,
                                              memoryRepository: memoryRepository,
                                              scheduler: scheduler)
    }
}
