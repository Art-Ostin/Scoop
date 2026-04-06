//
//  MapSearchViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 05/02/2026.
//

import Foundation
import MapKit

@Observable
final class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {

    var suggestions: [MKLocalSearchCompletion] = []
    var showSuggestions: Bool = true

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in
            self.suggestions = results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error:", error)
    }

    func updateQuery(_ fragment: String) {
        completer.queryFragment = fragment
    }
}
