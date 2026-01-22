//
//  EventSlot.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/08/2025.
//

import SwiftUI
import MapKit
import Contacts



struct EventSlot: View {
    
    let vm: EventViewModel
    @Binding var selectedProfile: ProfileModel?
    @State var profileModel: ProfileModel
    @State var imageSize: CGFloat = 0
    @State var showMessageScreen: Bool = false
    
    let locationManager = CLLocationManager()
    
    var body: some View {
        if let event = profileModel.event {
            
            ZStack {
                
                ScrollView {
                    VStack(spacing: 36) {
                        titleView
                        
                        imageView
                        
                        VStack(spacing: 24) {
                            FormatTimeAndPlace(time: event.time, place: event.place)
                            LargeClockView(targetTime: event.time) {}
                        }
                        
                        mapView(event: event)
                        
                        
                        
                    }
                    .padding(.top, 60)
                    .overlay(alignment: .topTrailing) {
                        messageButton
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    .onAppear {
                        locationManager.requestWhenInUseAuthorization()
                    }
                }
                
                .measure(key: ImageSizeKey.self) { $0.size.width }
                .onPreferenceChange(ImageSizeKey.self) { screenWidth in
                    imageSize = screenWidth - 48 //Adds 24 padding on each side
                }
                .fullScreenCover(isPresented: $showMessageScreen) {
                    Text("Message Screen here")
                    Button("Close") { showMessageScreen = false}
                }
            }
            
        }
    }
}


extension EventSlot {
    
    
    private var titleView: some View {
        Text("You're Meeting \(profileModel.profile.name)!")
            .font(.title(28, .medium))
    }

    @ViewBuilder
    private var imageView: some View {
        if let image = profileModel.image {
            Image(uiImage: image)
                .resizable()
                .defaultImage(imageSize)
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
        }
    }
    
    private var messageButton: some View {
        
        Button {
            showMessageScreen = true
        } label: {
            Image("ChatIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .font(.body(17, .bold))
                .padding(6)
                .background (
                    Circle()
                        .foregroundStyle(Color.background)
                        .stroke(100, lineWidth: 1.5, color: .black)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
    }
    
    @ViewBuilder
    private func openInMapsButton(coord: CLLocationCoordinate2D) -> some View {
        Button {
            let name = profileModel.event?.place.name ?? "Meet Location"
            let address = profileModel.event?.place.address ?? ""
            
            Task {
                // fallback if search doesn't find anything
                let fallback = MKMapItem(placemark: MKPlacemark(coordinate: coord))
                fallback.name = name

                do {
                    let request = MKLocalSearch.Request()
                    request.naturalLanguageQuery = [name, address].filter { !$0.isEmpty }.joined(separator: " ")
                    request.region = MKCoordinateRegion( center: coord, latitudinalMeters: 1500, longitudinalMeters: 1500)
                    
                    let response = try await MKLocalSearch(request: request).start()
                    let item = response.mapItems.first ?? fallback

                    item.openInMaps(launchOptions: [
                        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
                    ])
                } catch {
                    fallback.openInMaps(launchOptions: [
                        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
                    ])
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "map")
                    .font(.body(14, .bold))
                
                Text("Open Maps")
                    .foregroundStyle(Color.blue)
                    .font(.body(12, .bold))
            }
            .padding(.horizontal, 8)
            .tint(.blue)
            .padding(.vertical, 6)
            .glassIfAvailable()
        }
    }
    
    @ViewBuilder
    func mapView(event: UserEvent) ->  some View {
        let coord = CLLocationCoordinate2D(latitude: event.place.latitude, longitude: event.place.longitude)
        
        ZStack(alignment: .topTrailing) {
            
            Map(initialPosition: .camera(.init(centerCoordinate: coord, distance: 800))) {
                Marker(event.place.name ?? "",systemImage: "mappin", coordinate: coord)
                    .tint(.red)
                
                UserAnnotation()
                    .tint(.blue)
            }
            .tint(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .frame(width: imageSize, height: imageSize > 50 ? imageSize - 36 : imageSize)
            .padding(.top, 24)
            
            openInMapsButton(coord: coord)
                .padding(.vertical, 32)
                .padding(.horizontal, 12)
                .zIndex(2)
        }
    }
    
}
