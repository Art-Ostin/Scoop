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
    @State var showSheet: Bool = false
    
    var body: some View {
  
        VStack {
            MapTextField
                .focused($isFocused)
                .onChange(of: vm.searchText) { service.updateQuery(vm.searchText)}
                .onSubmit(of: .text) {
                    Task {
                        await vm.searchPlaces()
                    }
                }
                .onChange(of: isFocused) { service.showSuggestions = isFocused}
            
            if !service.suggestions.isEmpty && service.showSuggestions {
                List(service.suggestions, id: \.self) {suggestion in
                    VStack(alignment: .leading) {
                        Text(suggestion.title)
                        Text(suggestion.subtitle)
                            .font(.caption)
                    }
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
                }
                .background(Color.blue)
            }
        }
        .onAppear { isFocused = true}
//        .background(Color.background)
    }
}

#Preview {
    MapSearchView(vm: .init())
}

extension MapSearchView {
    
    private var MapTextField: some View {
        TextField("Search Maps", text: $vm.searchText)
            .padding(.leading, 34)
            .padding(.trailing, 12)
            .overlay(alignment: .leading) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.black)
                    .padding(.leading, 12)
            }
            .frame(height: 40)
            .glassIfAvailable(Capsule(), isClear: false)
            .contentShape(Capsule())
            .padding(.horizontal, 48)
            .focused($isFocused)
    }
}




/*
 
 //
 //
 //            .background(Capsule().fill(.ultraThinMaterial))
 //            .frame(height: 65)
 //            .padding(.horizontal, 16)
 //            .contentShape(Capsule())
 //            .glassIfAvailable(Capsule(), isClear: false)
 //            .clipShape(Capsule())
 //            .padding(.horizontal, 36)
 //            .focused($isFocused)
 */



/* Glass search bar when Searching 
 private var MapTextField: some View {
     TextField("Search Maps", text: $vm.searchText)
         .padding(.leading, 34)
         .padding(.trailing, 12)
         .overlay(alignment: .leading) {
             Image(systemName: "magnifyingglass")
                 .font(.system(size: 15, weight: .medium))
                 .foregroundStyle(.black)
                 .padding(.leading, 12)
         }
         .frame(height: 35)
         .background(Capsule().fill(.ultraThinMaterial))
         .frame(height: 65)
         .padding(.horizontal, 16)
         .contentShape(Capsule())
         .glassIfAvailable(Capsule(), isClear: false)
         .clipShape(Capsule())
         .padding(.horizontal, 36)
         .focused($isFocused)
 }

 */

