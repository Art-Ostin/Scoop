//
//  MapSearchView.swift
//  Scoop
//
//  Created by Art Ostin on 08/02/2026.
//

import SwiftUI
import MapKit

struct MapSearchView: View {
    @Bindable var vm: MapViewModel
    @Binding var sheet: MapSheets
    @State var service = LocationSearchService()

    var body: some View {
        VStack {
            if !service.suggestions.isEmpty && service.showSuggestions {
                searchSuggestionsView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .top) { headerBar }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onChange(of: vm.searchText) { _, newValue in service.updateQuery(newValue) }
    }
}

extension MapSearchView {
    
    private var headerBar: some View {
        HStack(alignment: .center, spacing: 12) {
            MapSearchBar(vm: vm)
                .frame(maxWidth: .infinity, alignment: .leading)

            DismissButton() { sheet = .optionsAndSearchBar }
                .frame(width: 40)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
    }
    
    
    private var searchSuggestionsView: some View {
            ScrollView {
                ClearRectangle(size: 75)
                let suggestions = service.suggestions

                LazyVStack(spacing: 0) {
                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                        SearchSuggestionRow(suggestion: suggestion, query: vm.searchText)
                            .onTapGesture {
                                sheet = .selected
                                Task { await searchLocation(suggestion: suggestion) }
                            }

                        if index < suggestions.count - 1 {
                            Divider().padding(.leading, 12)
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.gray.opacity(0.05), lineWidth: 0.5)
                )
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .customScrollFade(height: 50, showFade: true)
        }
    
    
    private func searchLocation (suggestion :MKLocalSearchCompletion) async {
//        isFocused = false
        vm.searchText = suggestion.title
        await vm.searchPlaces()
        
        if let first = vm.results.first {
            await MainActor.run { vm.selection = MapSelection(first) }
        }
    }
}


private struct SearchSuggestionRow: View {
    let suggestion: MKLocalSearchCompletion
    let query: String

    @State private var category: MKPointOfInterestCategory?
    
    //GPT Did this
    private var highlightedTitle: AttributedString {
        var attributed = AttributedString(suggestion.title)
        attributed.font = .body.weight(.regular)

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return attributed }

        let lowerTitle = suggestion.title.lowercased()
        let lowerQuery = trimmedQuery.lowercased()
        var searchRange = lowerTitle.startIndex..<lowerTitle.endIndex

        while let range = lowerTitle.range(of: lowerQuery, range: searchRange) {
            if let attrRange = Range(range, in: attributed) {
                attributed[attrRange].font = .body.weight(.bold)
            }
            searchRange = range.upperBound..<lowerTitle.endIndex
        }

        return attributed
    }
        
    var body: some View {
        HStack(spacing: 12) {
//            MapImageIcon(category: .restaurant, isSearch: true)
                VStack(alignment: .leading, spacing: 4) {
                Text(highlightedTitle)
                
                Text(suggestion.subtitle.isEmpty ? "Search Nearby" : suggestion.subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(Color(red: 0.54, green: 0.54, blue: 0.56)))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
