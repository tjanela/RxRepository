//
//  Identifiable.swift
//  Repository
//
//  Created by Tiago Janela on 2/11/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation

public protocol Identifiable: Hashable {
    associatedtype Id: Hashable
    var id: Id { get }
}
