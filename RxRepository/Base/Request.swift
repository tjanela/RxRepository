//
//  Request.swift
//  Repository
//
//  Created by Tiago Janela on 4/25/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//
import Foundation

public protocol Request: Hashable, Codable {
    var stringRepresentation: String { get }
}

extension String: Request {
    public var stringRepresentation: String { return self }
}

extension Int: Request {
    public var stringRepresentation: String { return "\(self)" }
}
