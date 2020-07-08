//
//  BaseCache.swift
//  Repository
//
//  Created by Tiago Janela on 1/30/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation

open class BaseCache<T, R: Hashable>: CacheProtocol {
    typealias T = T
    typealias R = R

    public init() { }

    open func load(request: R) -> T? {
        fatalError("Subclasses must implement")
    }

    open func save(request: R, object: T?) {
        fatalError("Subclasses must implement")
    }

    open func clear() {
        fatalError("Subclasses must implement")
    }
}
