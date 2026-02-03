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
         .frame(maxWidth: .infinity, alignment: .top)
         .overlay(alignment: .top) {
             HStack(alignment: .center, spacing: 8) {
                 searchBar
                     .frame(maxWidth: .infinity, alignment: .leading)
                 
                 DismissButton() { vm.showSearch = false }
                     .frame(width: 40)
             }
             .frame(maxWidth: .infinity)
             .padding(.horizontal, 16)
         }
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
             .frame(height: 45)
             .glassIfAvailable(Capsule(), isClear: false)
             .contentShape(Capsule())
             .focused($isFocused)
             .padding(.top, 16)
             .onSubmit(of: .text) { Task {  await vm.searchPlaces() }}

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
             ClearRectangle(size: 60)
             LazyVStack(spacing: 0) {
                 ForEach(service.suggestions, id: \.self) {suggestion in
                     SearchSuggestionRow(suggestion: suggestion)
                         .onTapGesture {
                             Task { await searchLocation(suggestion: suggestion)}
                         }
                     
        
                     
                         Divider()
                             .padding(.leading, 12)
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
        VStack(alignment: .leading) {
            Text(suggestion.title)
            Text(suggestion.subtitle)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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
