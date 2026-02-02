//
//  ToggleHelper.swift
//  Scoop
//
//  Created by Art Ostin on 29/10/2025.
//

import Foundation


extension Array where Element == String {
    mutating func toggle(_ s: String, limit: Int? = nil) {
        if let i = firstIndex(of: s) { remove(at: i) }
        else if limit.map({ count < $0 }) ?? true { append(s) }
    }
}
