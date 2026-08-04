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

    func updateQuery(_ fragment: String, region: MKCoordinateRegion? = nil) {
        if let region { completer.region = region }
        completer.queryFragment = fragment
    }
}
