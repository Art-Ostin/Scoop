//
//  MapSearchView.swift
//  Scoop
//
//  Created by Art Ostin on 08/02/2026.
//

import SwiftUI
import MapKit

struct MapSearchView: View {
    
    @State var service = LocationSearchService()
    
    @Bindable var vm: MapViewModel
    @Binding var sheet: MapSheets
    @FocusState.Binding var isFocused: Bool
    var showSuggestions: Bool {!service.suggestions.isEmpty && service.showSuggestions && !vm.searchText.isEmpty}
    var showRecentSearches: Bool { !vm.recentMapSearches.isEmpty  }
    
    @Binding var useSelectedDetent: Bool
    var body: some View {
        ScrollView {
            ClearRectangle(size: showSuggestions ? 68 : 80 )
            if showSuggestions {
                MapSearchBox { searchSuggestionList }
            } else {
                VStack(spacing: 28) {
                    if showRecentSearches {
                        MapSearchBox(text: "Recents") {recentSearchView }
                    }
                    MapSearchBox(text: "Find Nearby") {
                        ForEach(MapCategory.allCases) {categoryRow(category: $0)}
                    }
                }
            }
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
    
    @ViewBuilder
    private var recentSearchView: some View {
        VStack(spacing: 0) {
            ForEach(Array(vm.recentMapSearches.enumerated()), id: \.offset) { index, search in
                recentSearchRow(search: search)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)

                if index < vm.recentMapSearches.count - 1 {
                    MapDivider()
                        .padding(.leading, 53)
                        .padding(.trailing, 16)
                }
            }
        }
    }

    private var searchSuggestionList: some View {
        ForEach(Array(service.suggestions.enumerated()), id: \.offset) { index, suggestion in
            SearchSuggestionRow(suggestion: suggestion, query: vm.searchText)
                .onTapGesture { Task { await searchLocation(suggestion: suggestion)}}
            
            if index < service.suggestions.count - 1 {
                MapDivider().padding(.horizontal, 16)
            }
        }
    }

    @ViewBuilder
    func recentSearchRow(search: RecentPlace) -> some View {
        HStack(spacing: 0) {
            Button { searchRecentPlace(place: search) } label: {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.grayText)
                    
                    (
                        Text(search.title).foregroundStyle(.black).font(.body(17, .medium)) +
                    Text(" · \(search.town)").foregroundStyle(Color.grayText)
                    )
                    .font(.body(17, .regular))
                    .lineLimit(1)
                    .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Menu {
                clearRecentSeachButton(place: search)
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20, weight: .medium))
                    .contentShape(Rectangle())
                    .frame(width: 44, height: 44, alignment: .trailing)
                    .contentShape(Rectangle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func categoryRow (category: MapCategory) -> some View {
        Button {
            useSelectedDetent = true
            vm.selectedMapCategory = category
        } label: {
            VStack(spacing: 0){
                HStack(spacing: 12) {
                    MapCategoryIcon(sheet: $sheet, category: category, isMap: false, vm: vm, useSelectedDetent: $useSelectedDetent)
                    Text(category.description)
                        .font(.body(17, .bold))
                    Spacer()
                }
                .padding(16)
                if category != MapCategory.allCases.last {
                    MapDivider()
                        .padding(.leading, 64)
                        .padding(.trailing, 16)
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var headerBar: some View {
        HStack(alignment: .center, spacing: 12) {
            MapSearchBar(isFocused: $isFocused, vm: vm, sheet: $sheet)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            DismissButton() { sheet = .optionsAndSearchBar }
                .frame(width: 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .padding(.horizontal, 16)
    }
    
    private func searchLocation(suggestion :MKLocalSearchCompletion) async {
        //1. Logic to dismiss screen - gives snappy feel
        vm.selectedMapCategory = nil
        useSelectedDetent = true
        
        //2. Actually search the location in Maps
        vm.searchText = suggestion.title
        await vm.searchPlaces()
        if let first = vm.results.first {
            await MainActor.run { vm.selection = MapSelection(first) }
            
            //Save it to Defaults
            if let title = first.name, let town = first.placemark.locality  {
                if !title.isEmpty && !town.isEmpty {
                    vm.addSearchToDefaults(title: title, town: town)
                }
            }
        }
    }
    
    private func searchRecentPlace(place: RecentPlace) {
        let searchText = "\(place.title) \(place.town)"
        vm.selectedMapCategory = nil
        useSelectedDetent = true
        Task {
            vm.searchText = searchText
            await vm.searchPlaces()
            if let first = vm.results.first {
                await MainActor.run { vm.selection = MapSelection(first) }
            }
        }
    }
    
    private func clearRecentSeachButton(place: RecentPlace) -> some View {
        Button {
            vm.deleteSearchFromDefaults(place: place)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "minus.circle")
                    .foregroundStyle(Color.black)
                
                Text("Clear")
            }
        }
        .foregroundStyle(Color.black)
    }
}

private struct MapSearchBox<Content: View>: View {
    
    let text: String?
    
    let content: Content
    
    init(text: String? = nil, @ViewBuilder content: () -> Content) {
        self.text = text
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8)  {
            if let text {
                Text(text)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
            }
            LazyVStack(spacing: 0) {
                content
            }
//            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.gray.opacity(0.05), lineWidth: 0.5)
            )
            .padding(.horizontal, 16)
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



struct MapDivider: View {
    var body: some View {
        Rectangle()
            .foregroundStyle(Color(red: 0.91, green: 0.91, blue: 0.91))
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}
