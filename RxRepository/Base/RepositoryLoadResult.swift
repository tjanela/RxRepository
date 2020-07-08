//
//  RepositoryLoadResult.swift
//  Repository
//
//  Created by Tiago Janela on 1/31/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation

public enum RepositoryLoadResult<T: Equatable>: Equatable {
    public static func == (lhs: RepositoryLoadResult<T>, rhs: RepositoryLoadResult<T>) -> Bool {
        switch (lhs, rhs) {
        case (.value(let t1), .value(let t2)):
            return t1 == t2
        case (.noValue, .noValue),
             (.noValueDueToPolicy, .noValueDueToPolicy):
            return true
        case (.error(let e1), .error(let e2)):
            return areEqual(e1, e2)
        default:
            return false
        }
    }

    case value(T)
    case noValue
    case noValueDueToPolicy
    case error(Error)

    public func getValue() -> T? {
        switch self {
        case .value(let t):
            return t
        default:
            return nil
        }
    }
}
