//
//  Binding+Optional.swift
//  Scoop
//
//  Bridges a `Binding<Bool>` to a `Binding<String?>` so a parent that stores
//  a Bool flag can drive a child that expects an optional String binding
//  (e.g. popup containers whose presence is keyed by a non-nil draft string).
//

import SwiftUI

extension Binding where Value == Bool {
    /// Reads `nil` when `false`, `""` when `true`. Writing any non-nil value sets the bool to `true`.
    var asOptionalString: Binding<String?> {
        Binding<String?>(
            get: { wrappedValue ? "" : nil },
            set: { wrappedValue = ($0 != nil) }
        )
    }

    /// Generic variant — supply the value used when the bool is `true`.
    func asOptional<T>(_ presentValue: T) -> Binding<T?> {
        Binding<T?>(
            get: { wrappedValue ? presentValue : nil },
            set: { wrappedValue = ($0 != nil) }
        )
    }
}
