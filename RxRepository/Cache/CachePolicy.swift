//
//  CachePolicy.swift
//  Repository
//
//  Created by Tiago Janela on 1/30/20.
//  Copyright © 2020 Crédito Agrícola. All rights reserved.
//

import Foundation

/// Loosely modeled after NSURLRequest.CachePolicy
public enum CachePolicy: Hashable {
    case reloadIgnoringCache
    case returnCacheElseLoad
    case returnCacheDontLoad
}
