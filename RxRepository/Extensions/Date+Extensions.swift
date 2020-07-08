//
//  Date+Extensions.swift
//  Repository
//
//  Created by Tiago Janela on 5/27/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//
import Foundation
//
import SwifterSwift

public extension Date {
    var filenameFormat: String {
        string(withFormat: "YYYYMMddHHmmss")
    }
}
