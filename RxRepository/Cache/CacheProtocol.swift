//
//  CacheProtocol.swift
//  Repository
//
//  Created by Tiago Janela on 1/30/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation

protocol CacheProtocol {
    associatedtype T
    associatedtype R
    func load(request: R) -> T?
    func save(request: R, object: T?)
    func clear()
}
