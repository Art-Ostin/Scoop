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
    @Bindable var ui: EventUIState
    @State var profileModel: ProfileModel
    @State var imageSize: CGFloat = 0
    @Binding var dismissOffset: CGFloat?
    
    let locationManager = CLLocationManager()
    
    var body: some View {
        if let event = profileModel.event {
            
            ZStack {
                
                ScrollView {
                    VStack(spacing: 36) {
                        HStack {
                            titleView
                            Spacer()
//                            eventDetailsButton(event: event)
//                                .padding(.horizontal, 16)
                        }
                        
                        
                        imageView
                        
                        VStack(spacing: 24) {
                            timeAndPlace(event: event)
                            LargeClockView(targetTime: event.time) {}
                        }
                        
                        mapView(event: event)
                        
                        EventTextFormatter(ui: ui, profile: profileModel, event: event)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 60)
                    .overlay(alignment: .topTrailing) {
                        
//                        eventDetailsButton(event: event)
//                            .padding(.horizontal, 16)

                        messageButton
                            .padding(.horizontal, 24)
                            .padding(.vertical, 2)
                            .padding(.top, 8)
                    }
                    .overlay(alignment: .topLeading) {
//                        eventDetailsButton(event: event)
//                            .padding(.horizontal)
                    }
                    
                    .onAppear {
                        locationManager.requestWhenInUseAuthorization()
                    }
                    .padding(.bottom, 144)
                }
                .measure(key: ImageSizeKey.self) { $0.size.width }
                .onPreferenceChange(ImageSizeKey.self) { screenWidth in
                    imageSize = screenWidth - 48 //Adds 24 padding on each side
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}


extension EventSlot {
    
    
    private var titleView: some View {
        Text("Meeting")
            .font(.custom("SFProRounded-Bold", size: 32))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var imageView: some View {
        if let image = profileModel.image {
            Image(uiImage: image)
                .resizable()
                .defaultImage(imageSize)
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    if ui.selectedProfile == nil {
                        dismissOffset = nil
                        ui.selectedProfile = profileModel
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    Text(profileModel.profile.name)
                        .font(.body(24, .bold))
                        .padding(.vertical)
                        .padding(.horizontal)
                        .foregroundStyle(.white)
                }
//                .overlay(alignment: .bottomTrailing) { //For the moment button kept in top right
//                    messageButton
//                        .padding()
//                }
        }
    }
    
    private var messageButton: some View {
        Button {
            ui.showMessageScreen = profileModel
        } label: {
            Image("ChatIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .font(.body(17, .bold))
                .padding(8)
                .glassIfAvailable()
//
//                .background (
//                    Circle()
//                        .foregroundStyle(Color.background)
////                        .stroke(100, lineWidth: 1.5, color: .black)
//                )
//                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
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
            .frame(width: imageSize, height: imageSize > 50 ? imageSize - 24 : imageSize)
            
//            eventAddress(event: event)
//                .padding(4)
            
        }
    }
    
    private func timeAndPlace(event: UserEvent) -> some View {
        VStack(spacing: 14) {
            Text(EventFormatting.dayAndTime(event.time))
            
            Text(EventFormatting.placeName(event.place))
                .foregroundStyle(.accent)
                .onTapGesture {
                    Task { await MapsRouting.openMaps(place: event.place) }
                }
        }
        .font(.body(24, .bold))
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private func eventAddress(event: UserEvent) -> some View {
        Button {
            Task { await MapsRouting.openMaps(place: event.place) }
        } label: {
            Text(event.place.address ?? "")
                .font(.body(12, .medium))
                .underline(color: .black.opacity(0.6))
                .foregroundStyle(Color.black.opacity(0.6))
                .lineLimit(2)
                .padding(.trailing, 8)
                .padding(.vertical, 4)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 175)
                .background (
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(.ultraThinMaterial)
                )
        }
    }
    
    private func eventDetailsButton(event: UserEvent) -> some View {
        Button {
            ui.showEventDetails = event
        } label: {
            HStack(spacing: 10) {
                Image("CoolGuys")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                
                Text("Drink")
                    .font(.body(17, .bold))
            }
            .padding(8)
            .padding(.horizontal, 4)
            .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.background)
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 2)
                )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }

}
