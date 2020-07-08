//
//  JSONLoader.swift
//  Repository
//
//  Created by Tiago Janela on 5/22/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//
import Foundation

public final class JSONLoader {

    public static func loadModel<T: Decodable>(filename: String, from bundle: Bundle) -> T? {
        if let path = bundle.path(forResource: filename, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                return try? JSONDecoder().decode(T.self, from: data)
            } catch {
                return nil
            }
        }
        return nil
    }
}
