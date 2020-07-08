//
//  Error+Extensions.swift
//  Repository
//
//  Created by Tiago Janela on 2/3/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation

/**
 This is a equality on any 2 instance of Error.
 */
internal func areEqual(_ lhs: Error, _ rhs: Error) -> Bool {
    return lhs.reflectedString == rhs.reflectedString
}

internal extension Error {
    var reflectedString: String {
        // NOTE 1: We can just use the standard reflection for our case
        return String(reflecting: self)
    }

    // Same typed Equality
    func isEqual(to: Self) -> Bool {
        return self.reflectedString == to.reflectedString
    }

}

internal extension NSError {
    // Prevents scenario where one would cast swift Error to NSError
    // Whereby losing the associatedvalue in Obj-C realm.
    // (IntError.unknown as NSError("some")).(IntError.unknown as NSError)
    func isEqual(to: NSError) -> Bool {
        let lhs = self as Error
        let rhs = to as Error
        return self.isEqual(to) && lhs.reflectedString == rhs.reflectedString
    }
}
