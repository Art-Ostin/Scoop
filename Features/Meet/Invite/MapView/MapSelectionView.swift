//
//  MapSelectionView.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/07/2025.
//

import SwiftUI
import MapKit


struct MapSelectionView: View {

    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: MapViewModel
    
    let mapItem: MKMapItem
    
    
    let selectedLocation: (MKMapItem) -> Void
    
    

    
    var body: some View {
        
        VStack {
            HStack {
                VStack{
                    Text(mapItem.name ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(mapItem.placemark.title ?? "")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
                Spacer()
                
                Button {
                    vm.selection = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.gray, Color(.systemGray6))
                }
            }
            
            if let lookAround = vm.lookAroundScene {
                LookAroundPreview(scene: .constant(lookAround))
                    .frame(height:200)
                    .cornerRadius(16)
                    .padding()
            } else {
                ContentUnavailableView("No Preview", image: "eye.slash")
            }
            
            Button {
//                guard let mapItem else { return }
                selectedLocation(mapItem)
                dismiss()
            } label: {
                Text("Add Location")
                    .frame(width: 300, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accent)
                    )
                    .foregroundStyle(.white)
            }
//            .disabled(mapItem == nil)
        }
        .onAppear {
            fetchLookAround()
        }
        .onChange(of: vm.selection) { oldValue, newValue in
            fetchLookAround()
        }
        .padding()
        .padding(.top, 12)
    }
}
//
//#Preview {
//    MapSelectionView(vm: .constant(.init()), selectedPlace: .constant(nil), onCloseMap: {})
//}

extension MapSelectionView {
    
    //    private var mapItem: MKMapItem? {
    //        vm.selection?.value ?? vm.results.first(where: { MapSelection($0) == selection })
    //    }
    
    
    func fetchLookAround() {
        vm.lookAroundScene = nil
        Task {
            let request = MKLookAroundSceneRequest(mapItem: mapItem)
            vm.lookAroundScene = try? await request.scene
        }
    }
}
