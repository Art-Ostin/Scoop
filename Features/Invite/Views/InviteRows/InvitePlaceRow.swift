//
//  InvitePlaceRow.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

struct InvitePlaceRow: View {
    
    @Bindable var ui: TimeAndPlaceUIState
    @Binding var eventLocation: EventLocation?
    @Binding var showMapView: Bool
    
    let isMultipleTimes: Bool //If there are decrease topPadding as looks cleaner
    
    var body: some View {
        HStack {
            inviteTypeText(.where)
            Spacer()
            chooseButton
        }
        .padding(.top, placeTopPadding)
        .padding(.bottom, placeBottomPadding)
    }
}

extension InvitePlaceRow {
    
    private var noLocationPlaceholder: some View {
        Text("Select Place")
            .font(.body(15, .medium))
            .foregroundStyle(Color(red: 0.3, green: 0.3, blue: 0.3))
    }
    
    private var chooseButton: some View {
        Button {
            withAnimation(.snappy) { showMapView.toggle() }
        } label: {
            HStack(spacing: 12) {
                if let eventLocation {
                    VStack(alignment: .trailing) {
                        Text(eventLocation.name ?? "")
                            .font(.body(17, .medium))
                            .foregroundStyle(Color.black)
                        Text(FormatEvent.addressWithoutCountry(eventLocation.address))
                            .font(.footnote)
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                    }
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                } else {
                    Text("Choose Place")
                        .font(.body(16, .regular))
                        .foregroundStyle(Color(white: 0.4))
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }
                
                //Don't show chevron when popup open as smoother show clear rectangle so content doesn't shift
                Image("InviteChevron")
                    .opacity(ui.popupOpenDelayed ? 0 : 1)
            }
        }
    }
    
    private var placeTopPadding: CGFloat {
        eventLocation != nil ? 16 : 28
    }
    
    private var placeBottomPadding: CGFloat {
        eventLocation != nil ? 24 : 28
    }
}


/*
 HStack(spacing: 12) {
     Text("Choose Time")
         .kerning(0.32)
         .font(.body(16, .regular))
         .foregroundStyle(Color(white: 0.4))
     Image("InviteChevron")
 }
 
 struct InvitePlaceRow: View {
     
     @Binding var eventLocation: EventLocation?
     @Binding var showMapView: Bool
         
     var body: some View {
         HStack(spacing: 16) {
             
             
             Group {
                 if let location = eventLocation {
                     addressText(location: location)
                 } else {
                     noLocationPlaceholder
                 }
             }
             .frame(maxWidth: .infinity, alignment: .leading)
             openMapButton
                 .fixedSize()
         }
     }
 }

 extension InvitePlaceRow {
     
     private var noLocationPlaceholder: some View {
         Text("Select Place")
             .font(.body(15, .medium))
             .foregroundStyle(Color(red: 0.3, green: 0.3, blue: 0.3))
     }
     
     
     private func addressText(location: EventLocation) -> some View {
         VStack(alignment: .leading) {
             Text(location.name ?? "")
                 .font(.body(16, .medium))
             Text(FormatEvent.addressWithoutCountry(location.address))
                 .font(.footnote)
                 .foregroundStyle(.gray)
                 .lineLimit(1)
         }
         .frame(maxWidth: .infinity, alignment: .leading)
     }
     
     private var openMapButton: some View {
         Button {
             withAnimation(.snappy) { showMapView.toggle() }
         } label: {
             Image("LightBlackMapIcon")
                 .padding(6)
                 .background(
                     Circle().foregroundStyle(.white).opacity(0.7)
                 )
                 .overlay {
                     Circle()
                         .strokeBorder(Color.accent.opacity(0.5), lineWidth: 0.5)
                 }
                 .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                 .contentShape(Rectangle())
                 .padding(14)
         }
         .buttonStyle(.plain)
         .padding(-14)
     }
 */
