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
    @FocusState.Binding var isFocused: Bool
    var showSuggestions: Bool {!service.suggestions.isEmpty && service.showSuggestions && !vm.searchText.isEmpty}

    @State var service = LocationSearchService()
    
    var body: some View {
        ScrollView {
            ClearRectangle(size: showSuggestions ? 75 : 84)
            
            if !showSuggestions {
                Text("Find Nearby")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
            }
            
            LazyVStack(spacing: 0) {
                if showSuggestions {
                    searchSuggestionList
                } else {
                    ForEach(MapCategory.allCases) {categoryRow(category: $0)}
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .top) { headerBar }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onChange(of: vm.searchText) { _, newValue in service.updateQuery(newValue) }
    }
}

extension MapSearchView {
    
    private var headerBar: some View {
        HStack(alignment: .center, spacing: 12) {
            MapSearchBar(isFocused: $isFocused, vm: vm, sheet: $sheet)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            DismissButton() { sheet = .optionsAndSearchBar }
                .frame(width: 40)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
    }
    
    private var searchSuggestionList: some View {
        ForEach(Array(service.suggestions.enumerated()), id: \.offset) { index, suggestion in
            SearchSuggestionRow(suggestion: suggestion, query: vm.searchText)
                .onTapGesture { Task { await searchLocation(suggestion: suggestion)}}
            
            if index < service.suggestions.count - 1 {
                Divider().padding(.leading, 16)
            }
        }
    }
    
    
    private func categoryRow (category: MapCategory) -> some View {
        Button {
            sheet = .optionsAndSearchBar
            vm.selectedMapCategory = category
        } label: {
            VStack(spacing: 0){
                HStack(spacing: 12) {
                    MapCategoryIcon(sheet: $sheet, category: category, isMap: false, vm: vm)
                    Text(category.description)
                        .font(.body(17, .bold))
                    Spacer()
                }
                .padding(16)
                if category != MapCategory.allCases.last {
                    Divider()
                        .padding(.leading, 64)
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func searchLocation(suggestion :MKLocalSearchCompletion) async {
        //1. Logic to dismiss screen - gives snappy feel
        vm.selectedMapCategory = nil
        sheet = .searchBar
        
        //2. Actually search the location in Maps
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
    
    //GPT Did this Be careful
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


/*
 private var searchSuggestionsView: some View {
     ScrollView {
         ClearRectangle(size: 75)
         let suggestions = service.suggestions
         
         LazyVStack(spacing: 0) {
             
             if showSuggestions {
                 searchSuggestionList
             } else {
                 
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

 */
