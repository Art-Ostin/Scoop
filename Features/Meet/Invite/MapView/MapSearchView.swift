//
//  MapSearchView.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/07/2025.
//


 import SwiftUI
 import MapKit


 @Observable class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {
     
     var suggestions: [MKLocalSearchCompletion] = []
     
     var showSuggestions: Bool = true
     
     let completer = MKLocalSearchCompleter()
     
     override init () {
         super.init()
         completer.delegate = self
     }
     
     func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
         suggestions = completer.results
     }
     
     func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
         print("Search completer error:", error)
     }
     
     func updateQuery (_ fragment: String) {
         completer.queryFragment = fragment
     }
 }

 struct MapSearchView: View {
     
     @State var service = LocationSearchService()
     @FocusState var isFocused: Bool
     
     @State var vm: MapViewModel

     
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
             .onSubmit(of: .text) { Task {  await vm.searchPlaces() }}
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
         Task {
             await vm.searchPlaces()
             
             if let first = vm.results.first {
                 vm.mapSelection = first
             }
         }
     }
     
     private var suggestionsCard: some View {
         ScrollView {
             ClearRectangle(size: 75)
             LazyVStack(spacing: 0) {
                 ForEach(service.suggestions.indices, id: \.self) { index in
                     let suggestion = service.suggestions[index]
                     SearchSuggestionRow(suggestion: suggestion)
                         .onTapGesture {
                             Task { await searchLocation(suggestion: suggestion)}
                         }
                     if index != service.suggestions.indices.last {
                         Divider()
                             .padding(.leading, 12)
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
     }
}

private struct SearchSuggestionRow: View {
    let suggestion: MKLocalSearchCompletion

    @State private var category: MKPointOfInterestCategory?
    let query: String
    
    private var highlightedTitle: AttributedString {
        var attributed = AttributedString(suggestion.title)
        attributed.font = .body.weight(.medium)

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
            if let category {
                MapImageIcon(category: category)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                Text(suggestion.subtitle.isEmpty ? "Search Nearby" : suggestion.subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(Color(red: 0.54, green: 0.54, blue: 0.56)))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .task(id: suggestion) {
            await loadCategoryIfNeeded()
        }
    }
    
    private func loadCategoryIfNeeded() async {
        guard category == nil else { return }
        let request = MKLocalSearch.Request(completion: suggestion)
        do {
            let response = try await MKLocalSearch(request: request).start()
            await MainActor.run {
                category = response.mapItems.first?.pointOfInterestCategory
            }
        } catch {
            await MainActor.run { category = nil }
        }
    }
}






/*
 
 
 
 .onTapGesture {
     Task {
         await vm.searchPlaces()
         
         if let first = vm.results.first {
             vm.mapSelection = first
         }
     }
     isFocused = false
     vm.searchText = suggestion.title
 }
 */



/*
 
 @Observable class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {
     
     var suggestions: [MKLocalSearchCompletion] = []
     
     var showSuggestions: Bool = true
     
     let completer = MKLocalSearchCompleter()
     
     override init () {
         super.init()
         completer.delegate = self
     }
     
     func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
         suggestions = completer.results
     }
     
     func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
         print("Search completer error:", error)
     }
     
     func updateQuery (_ fragment: String) {
         completer.queryFragment = fragment
     }
 }

 struct MapSearchView: View {
     
     @State var service = LocationSearchService()
     @FocusState var isFocused: Bool
     
     @Environment(\.dismiss) private var dismiss
     @Bindable var vm: MapViewModel
     
     var body: some View {
         VStack(spacing: 16) {
             header

             if !service.suggestions.isEmpty && service.showSuggestions {
                 suggestionsCard
             }

             Spacer(minLength: 0)
         }
         .padding(.top, 12)
         .background(Color(.systemGroupedBackground).ignoresSafeArea())
         .onAppear { isFocused = true }
         .onChange(of: vm.searchText) { service.updateQuery(vm.searchText) }
         .onChange(of: isFocused) { service.showSuggestions = isFocused || !vm.searchText.isEmpty }
     }
 }

 #Preview {
     MapSearchView(vm: .init())
 }

 extension MapSearchView {

     private var header: some View {
         HStack(spacing: 12) {
             GlassSearchBar(showSheet: $vm.showSearch)
             .onSubmit(of: .text) {
                 Task { await vm.searchPlaces() }
             }

             Button {
                 dismiss()
             } label: {
                 Image(systemName: "xmark")
                     .font(.body.weight(.semibold))
                     .foregroundStyle(Color.primary)
                     .frame(width: 36, height: 36)
                     .background(Circle().fill(Color(.secondarySystemBackground)))
             }
             .buttonStyle(.plain)
         }
         .padding(.horizontal, 16)
     }

     private var suggestionsCard: some View {
         ScrollView {
             LazyVStack(spacing: 0) {
                 ForEach(service.suggestions.indices, id: \.self) { index in
                     let suggestion = service.suggestions[index]
                     SearchSuggestionRow(suggestion: suggestion)
                         .contentShape(Rectangle())
                         .onTapGesture {
                             vm.searchText = suggestion.title
                             isFocused = false
                             Task {
                                 await vm.searchPlaces()
                                 if let first = vm.results.first {
                                     vm.mapSelection = first
                                 }
                             }
                         }

                     if index != service.suggestions.indices.last {
                         Divider()
                             .padding(.leading, 56)
                     }
                 }
             }
             .padding(.vertical, 8)
             .background(Color(.systemBackground))
             .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
             .overlay(
                 RoundedRectangle(cornerRadius: 24, style: .continuous)
                     .stroke(Color.black.opacity(0.05), lineWidth: 1)
             )
             .padding(.horizontal, 16)
         }
         .scrollIndicators(.hidden)
     }
 }

 private struct SearchSuggestionRow: View {
     let suggestion: MKLocalSearchCompletion

     var body: some View {
         HStack(spacing: 12) {
             ZStack {
                 Circle()
                     .fill(Color.gray.opacity(0.2))
                     .frame(width: 32, height: 32)
                 Image(systemName: "magnifyingglass")
                     .font(.system(size: 14, weight: .semibold))
                     .foregroundStyle(Color.gray)
             }

             VStack(alignment: .leading, spacing: 2) {
                 Text(suggestion.title)
                     .font(.body.weight(.semibold))
                     .foregroundStyle(Color.primary)
                 Text(suggestion.subtitle)
                     .font(.subheadline)
                     .foregroundStyle(Color.secondary)
             }

             Spacer(minLength: 0)
         }
         .padding(.horizontal, 16)
         .padding(.vertical, 10)
     }
 }

 */
