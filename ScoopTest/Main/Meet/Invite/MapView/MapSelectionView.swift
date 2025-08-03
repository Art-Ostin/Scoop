//
//  MapSelectionView.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/07/2025.
//

import SwiftUI
import MapKit


struct MapSelectionView: View {
    
    @Binding var vm: MapViewModel
    @Binding var selectedPlace: MKMapItem?
    @Binding var vm2: SendInviteViewModel
    
    let onCloseMap: () -> Void
    
    
    var body: some View {
        VStack {
            HStack {
                VStack{
                    Text(vm.mapSelection?.placemark.name ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(vm.mapSelection?.placemark.title ?? "")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                    
                }
                Spacer()
                
                Button {
                    vm.mapSelection = nil
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
                selectedPlace = vm.mapSelection
                vm2.event.location = vm.mapSelection
                onCloseMap()
            } label: {
                Text("Add Location")
                    .frame(width: 300, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accent)
                    )
                    .foregroundStyle(.white)
            }
        }
        .onAppear {
            fetchLookAround()
        }
        .onChange(of: vm.mapSelection) { oldValue, newValue in
            fetchLookAround()
        }
        .padding()
    }
}

extension MapSelectionView {
    
    func fetchLookAround() {
        
        if let selection = vm.mapSelection {
            vm.lookAroundScene = nil
            Task {
                let request = MKLookAroundSceneRequest(mapItem: selection)
                vm.lookAroundScene = try? await request.scene
            }
        }
    }
}
