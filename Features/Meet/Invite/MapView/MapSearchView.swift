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
            MapTextField
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
            }
        }
        .onAppear { isFocused = true}
    }
}

#Preview {
    MapSearchView(vm: .init())
}

extension MapSearchView {

     private var MapTextField: some View {

         TextField(text: $vm.searchText) {
             HStack(spacing: 6) {
                 Image(systemName: "magnifyingglass")
                 Text("Search")
                 Spacer()
             }
             .frame(maxWidth: .infinity)
             .padding()
             .background(
                 Color.grayBackground.opacity(0.9)
             )
             .padding()
             .glassIfAvailable()
         }
     }
}



