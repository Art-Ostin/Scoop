//
//  EventSlot.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/08/2025.
//

//Accidental duplicate, delete if possible
/*
 import SwiftUI
 import MapKit
 import Contacts

 
 struct EventSlotContainer: View {
     
     @State var eventProfile: EventProfile
     @Bindable var ui: EventUIState
     
     
     let vm: EventViewModel
     
     @Binding var showfrozenInfo: Bool
     
     @State var imageSize: CGFloat = 0
     let isFrozenEvent: Bool
     let locationManager = CLLocationManager()
     
     var body: some View {
         
         ZStack {
             ScrollView {
                 VStack(spacing: 36) {
                     titleView
                     EventImageView(ui: ui, eventProfile: eventProfile, imageSize: imageSize)
                     EventHeaderDetails(ui: ui, event: eventProfile.event) {openMaps()}
                     EventMapView(event: eventProfile.event, imageSize: imageSize) {openMaps()}}
                 
                 eventInfo(event:  eventProfile.event)
             }
             .padding(.top, 60)
             .onAppear {
                 locationManager.requestWhenInUseAuthorization()
             }
             .padding(.bottom, 144)
             .overlay(alignment: .topTrailing) {
                 messageButton
                     .padding(.horizontal, 24)
                     .padding(.vertical, 6)
             }
         }
         .measure(key: ImageSizeKey.self) { $0.size.width }
         .onPreferenceChange(ImageSizeKey.self) { screenWidth in
             imageSize = screenWidth - 48 //Adds 24 padding on each side
         }
         .scrollIndicators(.hidden)
         .customScrollFade(height: 100, showFade: true)
     }
 }

 extension EventSlotContainer {
     
     private var titleView: some View {
         
         HStack(alignment: .top, spacing: 6) {
             Text("Meeting")
                 .font(.custom("SFProRounded-Bold", size: 32))
             
             if isFrozenEvent {
                 Button {
                     showfrozenInfo.toggle()
                 } label: {
                     Image(systemName: "info.circle")
                         .foregroundStyle(Color(red: 0.26, green: 0.26, blue: 0.26))
                         .contentShape(Circle())
                 }
             }
         }
         .frame(maxWidth: .infinity, alignment: .leading)
         .padding(.horizontal, 16)
     }
         
     private var messageButton: some View {
         Button {
             ui.showMessageScreen = eventProfile.profile
         } label: {
             Image("roundMessageIcon")
                 .resizable()
                 .scaledToFit()
                 .frame(width: 22, height: 22)
                 .font(.body(17, .bold))
                 .padding(6)
                 .glassIfAvailable(isClear: true)
                 .padding(24)
                 .contentShape(Rectangle())
                 .padding(-24)
         }
     }
             
     private func eventAddress(event: UserEvent) -> some View {
         Button {
             openMaps(event)
         } label: {
             Text(event.location.address ?? "")
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
 }

 extension EventSlotContainer {
     
     
     private func address(event: UserEvent) -> some View {
         Button {
             openMaps(event)
         } label: {
             Text(removingTrailingCountry(from: EventFormatting.placeFullAddress(place: event.location)))
                 .font(.body(12, .regular))
                 .underline(color: .grayText)
                 .foregroundStyle(Color.grayText)
                 .frame(width: 300, alignment: .leading)
                 .lineLimit(2)
                 .multilineTextAlignment(.leading)
         }
     }
     
     private func removingTrailingCountry(from address: String) -> String {
         guard let i = address.lastIndex(of: ",") else { return address }
         return String(address[..<i]).trimmingCharacters(in: .whitespacesAndNewlines)
     }
     
     private var confirmedText: Text {
         Text("You’ve both confirmed so don’t worry, they’ll be there! If you stand them up you're ")
             .foregroundStyle(Color.grayText)
             .font(.body(16, .medium))

         + Text("blocked.")
             .font(.body(16, .bold))
             .underline()
             .foregroundStyle(Color.black)
     }
     
     
     
     @discardableResult
     private func openMaps() -> Bool {
         MapsRouter.openMaps(defaults: vm.defaults, item: eventProfile.event.location.mapItem, withDirections: true)
     }
 }

 */
