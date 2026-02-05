//
//  MapSearchView.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/07/2025.
//


 import SwiftUI
 import MapKit


@MainActor
@Observable
final class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {

    var suggestions: [MKLocalSearchCompletion] = []
    var showSuggestions: Bool = true

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error:", error)
    }

    func updateQuery(_ fragment: String) {
        completer.queryFragment = fragment
    }
}

 struct MapSearchView: View {
     
     @State var service = LocationSearchService()
     @FocusState var isFocused: Bool
     @Bindable var vm: MapViewModel
     
     
     
     var body: some View {
         VStack {
             if !service.suggestions.isEmpty && service.showSuggestions {
                 suggestionsCard
             }
         }
         .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
         .overlay(alignment: .top) {headerBar}
         .background(Color(.systemGroupedBackground).ignoresSafeArea())
         .onAppear { isFocused = true }
         .onChange(of: vm.searchText) { service.updateQuery(vm.searchText)
         }
     }
 }

 #Preview {
     MapSearchView(vm: .init())
 }

 extension MapSearchView {
     
     private var headerBar: some View {
         HStack(alignment: .center, spacing: 12) {
             searchBar
                 .frame(maxWidth: .infinity, alignment: .leading)
             
             DismissButton() { vm.showSearch = false }
                 .frame(width: 40)
         }
         .frame(maxWidth: .infinity)
         .padding(16)
     }
     
     private var searchBar: some View {
         TextField("Search Maps", text: $vm.searchText)
             .padding(.leading, 34)
             .padding(.trailing, 12)
             .overlay(alignment: .leading) {
                 Image(systemName: "magnifyingglass")
                     .font(.system(size: 15, weight: .medium))
                     .foregroundStyle(.black)
                     .padding(.leading, 12)
             }
             .overlay(alignment: .trailing) {deleteSearchButton}
             .frame(height: 45)
             .glassIfAvailable(Capsule(), isClear: false)
             .contentShape(Capsule())
             .focused($isFocused)
             .onSubmit(of: .text) { Task {
                 await vm.searchPlaces()
                 if let first = vm.results.first {
                     await MainActor.run { vm.showSearch = false }
                     await MainActor.run { vm.selection = MapSelection(first) }
                 }
             }
        }
     }
     
     @ViewBuilder
     private var deleteSearchButton: some View {
         if !vm.searchText.isEmpty {
             Button {
                 vm.searchText = ""
             } label : {
                 Image(systemName: "xmark")
                     .font(.body(12, .bold))
                     .foregroundStyle(Color.white)
                     .padding(4)
                     .background (
                        Circle()
                            .foregroundStyle(Color(red: 0.53, green: 0.53, blue: 0.56))
                     )
                     .scaleEffect(0.8)
                     .padding(.horizontal, 12)
             }
         }

     }
     
     private func searchLocation (suggestion :MKLocalSearchCompletion) async {
         isFocused = false
         vm.searchText = suggestion.title
         await vm.searchPlaces()

         if let first = vm.results.first {
             // Close search first so the details sheet can present cleanly.
             await MainActor.run { vm.showSearch = false }
             await MainActor.run { vm.selection = MapSelection(first) }
         }
     }
     
     
     private var suggestionsCard: some View {
         return ScrollView {
             ClearRectangle(size: 75)
             let suggestions = service.suggestions
             LazyVStack(spacing: 0) {
                 ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                     
                     SearchSuggestionRow(suggestion: suggestion, query: vm.searchText)
                         .onTapGesture {
                             Task { await searchLocation(suggestion: suggestion)
}
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
            MapImageIcon(category: .restaurant, isSearch: true)

                
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
