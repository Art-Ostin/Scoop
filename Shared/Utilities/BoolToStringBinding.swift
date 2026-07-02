//
//  BoolToStringBinding.swift
//  Scoop
//
//  Created by Art Ostin on 05/05/2026.
//

import SwiftUI

//Used to convert bools to values.
extension Binding where Value == Bool {
    // Reads `nil` when `false`, `""` when `true`. Writing any non-nil value sets the bool to `true`.
    var asOptionalString: Binding<String?> {
        Binding<String?>(
            get: { wrappedValue ? "" : nil },
            set: { wrappedValue = ($0 != nil) }
        )
    }
}

extension Binding {
    // Bridges optional-driven state to a Bool binding for `isPresented:` APIs:
    // `true` while non-nil; setting `false` clears it to `nil`.
    func isPresent<Wrapped>() -> Binding<Bool> where Value == Wrapped? {
        Binding<Bool>(
            get: { wrappedValue != nil },
            set: { if !$0 { wrappedValue = nil } }
        )
    }
}
