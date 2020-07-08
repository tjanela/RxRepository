//
//  CacheEntry.swift
//  Repository
//
//  Created by Tiago Janela on 2/2/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation

struct CacheEntry<T: Codable>: Codable {
    let key: String
    let expiresAt: Date
    let value: T

    init(key: String, expiresAt: Date, value: T) {
        self.key = key
        self.expiresAt = expiresAt
        self.value = value
    }

    var isExpired: Bool {
        expiresAt < Date()
    }
}
