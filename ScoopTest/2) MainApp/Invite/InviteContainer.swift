//
//  SendInviteView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI
import MapKit

struct SendInviteView: View {
    
    @Bindable var ProfileViewModel: ProfileViewModel
    
    let name: String

    @State var showTypePopup: Bool = false
    
    @State var typeInputText: String = ""
    
    @State var typeDefaultOption: String = ""
    
    @State var showMessageScreen: Bool = false
    
    @State var showTimePopup: Bool = false
    
    @State var selectedTime: Date? = nil
    
    @State var showMapView: Bool = false
    
    @State var selectedLocation: MKMapItem?
    
    var body: some View {
        
        ZStack {
            PopupTemplate(profileImage: "Image1", title: "Meet Arthur") {
                
                VStack(spacing: 30) {
                                        
                    InviteTypeRowView(typeDefaultOption: typeDefaultOption, typeInputText: $typeInputText, showTypePopup: $showTypePopup, showMessageScreen: $showMessageScreen)
                    
                    
                    Divider()
                    
                    InviteTimeRowView(showTimePopup: $showTimePopup, selectedTime: $selectedTime)
                    
                    
                    Divider()
                    
                    InvitePlaceRowView(showMapView: $showMapView, selectedPlace: $selectedLocation)
                    
                    ActionButton2(text: "Confirm & Send", isValid: true, onTap: {
                        ProfileViewModel.showInvite.toggle()
                        ProfileViewModel.inviteSent = true
                    })
                    
                }
            }
            
            if showTypePopup {
                
                SelectTypeView(typeDefaultOption: $typeDefaultOption, showTypePopup: $showTypePopup)
            }
            
            if showTimePopup {
                
                SelectTimeView(selectedTime: $selectedTime, showTimePopup: $showTimePopup)
                
            }
            
        }
        .sheet(isPresented: $showMessageScreen) {
            InviteAddMessageView(typeInputText: $typeInputText, typeDefaultOption: $typeDefaultOption, showTypePopup: $showTypePopup)
        }
        .fullScreenCover(isPresented: $showMapView) {
            MapView(selectedPlace: $selectedLocation)
        }
    }
}

#Preview {
    SendInviteView(ProfileViewModel: ProfileViewModel(profile: CurrentUserStore.shared.user!), name: "Arthur", typeDefaultOption: "")
}
