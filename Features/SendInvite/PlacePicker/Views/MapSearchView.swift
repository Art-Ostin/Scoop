//
//  MapSearchView.swift
//  Scoop
//
//  Created by Art Ostin on 08/02/2026.
//

import SwiftUI
import MapKit

struct MapSearchView: View {
    
    //Injected
    @Bindable var vm: MapViewModel
    @Binding var sheet: MapSheets
    @FocusState.Binding var isFocused: Bool
    @Binding var useSelectedDetent: Bool

    //Local view state
    @State private var service = LocationSearchService()

    var showSuggestions: Bool {!service.suggestions.isEmpty && service.showSuggestions && !vm.searchText.isEmpty}
    var showRecentSearches: Bool { !vm.recentMapSearches.isEmpty  }

    var body: some View {
        ScrollView {
            if showSuggestions {
                MapSearchBox { searchSuggestionList }
            } else {
                VStack(spacing: Spacing.lg) {
                    if showRecentSearches {
                        MapSearchBox(text: "Recents") {recentSearchView }
                    }
                    MapSearchBox(text: "Find Nearby") {
                        ForEach(MapCategory.allCases) {categoryRow(category: $0)}
                    }
                }
            }
        }
        //Geometry: clears the headerBar overlay — former spacer size plus the 8pt implicit ScrollView child gap
        .contentMargins(.top, showSuggestions ? 76 : 88, for: .scrollContent)
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
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xxs)

                if index < vm.recentMapSearches.count - 1 {
                    MapDivider()
                        .padding(.leading, 53) //Geometry: aligns the divider with the row's text column
                        .padding(.trailing, Spacing.md)
                }
            }
        }
    }

    private var searchSuggestionList: some View {
        ForEach(Array(service.suggestions.enumerated()), id: \.offset) { index, suggestion in
            SearchSuggestionRow(suggestion: suggestion, query: vm.searchText)
                .onTapGesture { Task { await searchLocation(suggestion: suggestion)}}
            
            if index < service.suggestions.count - 1 {
                MapDivider()
                    .padding(.leading, 62) //Geometry: aligns the divider with the row's text column
                    .padding(.trailing, Spacing.md)
            }
        }
    }

    @ViewBuilder
    func recentSearchRow(search: RecentPlace) -> some View {
        HStack(spacing: 0) {
            Button { searchRecentPlace(place: search) } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                    
                    (
                        Text(search.title).foregroundStyle(Color.textPrimary).font(.body(17, .medium)) +
                    Text(" · \(search.town)").foregroundStyle(Color.textSecondary)
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
                    .foregroundStyle(Color.textPrimary)
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
            vm.selectCategory(category)
        } label: {
            VStack(spacing: 0){
                HStack(spacing: Spacing.sm) {
                    MapCategoryIcon(sheet: $sheet, category: category, isMap: false, vm: vm, useSelectedDetent: $useSelectedDetent)
                    Text(category.description)
                        .font(.body(17, .bold))
                    Spacer()
                }
                .padding(Spacing.md)
                if category != MapCategory.allCases.last {
                    MapDivider()
                        .padding(.leading, 64) //Geometry: aligns the divider with the row's text column
                        .padding(.trailing, Spacing.md)
                }
            }
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var headerBar: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            MapSearchBar(isFocused: $isFocused, vm: vm, sheet: $sheet)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // TEMP: glass button commented out for ButtonTest preview
            EmptyView()
            /*
            GlassButton(padding: 6) {
                sheet = .optionsAndSearchBar
            } buttonLabel: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(Color.textPrimary)
            }
            */
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.md)
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
            HStack(spacing: Spacing.xs) {
                Image(systemName: "minus.circle")
                    .foregroundStyle(Color.textPrimary)
                
                Text("Clear")
            }
        }
        .foregroundStyle(Color.textPrimary)
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
        VStack(alignment: .leading, spacing: Spacing.xs)  {
            if let text {
                Text(text)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.lg)
            }
            LazyVStack(spacing: 0) {
                content
            }
            .background(Color(.systemBackground))
            .clipShape(.rect(cornerRadius: CornerRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .stroke(Color.border.opacity(0.2), lineWidth: 0.5)
            )
            .padding(.horizontal, Spacing.gutter)
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
        HStack(spacing: Spacing.sm) {
            searchImageIcon
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(highlightedTitle)
                
                Text(suggestion.subtitle.isEmpty ? "Search Nearby" : suggestion.subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
    
    private var searchImageIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1, green: 0, blue: 0.44),
                            Color(red: 0.67, green: 0, blue: 0.27)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Image(systemName: "mappin")
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.white)
                .font(.system(size: 33 * 0.42, weight: .semibold))

        }
        .frame(width: 33, height: 33)
    }
}



struct MapDivider: View {
    var body: some View {
        Rectangle()
            .foregroundStyle(Color.border)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}
