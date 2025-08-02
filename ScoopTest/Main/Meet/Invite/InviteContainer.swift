//
//  SendInviteView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.


import SwiftUI
import MapKit

@Observable final class SendInviteViewModel {

    var event: Event
    
    init(profile1: UserProfile, profile2: UserProfile) {
        self.event = Event(profile: profile1, profile2: profile2)
    }
    var showTypePopup: Bool = false
    var showMessageScreen: Bool = false
    var showTimePopup: Bool = false
    var showMapView: Bool = false
    
}


struct SendInviteView: View {
    
    
    @Binding var profileVM: ProfileViewModel
    @State var vm: SendInviteViewModel
    
    
    
    init(profile1: UserProfile, profile2: UserProfile, profileVM: Binding<ProfileViewModel>) {
        self._vm = State(initialValue: SendInviteViewModel(profile1: profile1, profile2: profile2))
        self._profileVM = profileVM
    }
        
    var body: some View {
        
        ZStack {
            
            PopupTemplate(profileImage: "Image1", title: "Meet Arthur") {
                
                VStack(spacing: 30) {
                    
                    InviteTypeRow
                    
                    Divider()
                    InviteTimeRow
                    Divider()
                    InvitePlaceRow
                    
                    ActionButton(isValid: true, text: "Confirm & Send", onTap: {
                        profileVM.showInvite.toggle()
                        profileVM.inviteSent = true
                    })
                }
            }
            if vm.showTypePopup {
                SelectTypeView(vm: $vm)
                    .offset(y: 36)
            }
            if vm.showTimePopup {
                SelectTimeView2(vm: $vm)
                    .offset(y: 156)
                    .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
            }
        }
        .sheet(isPresented: $vm.showMessageScreen) {
            InviteAddMessageView(vm: $vm)
        }
        .fullScreenCover(isPresented: $vm.showMapView) {
            MapView(vm2: $vm)
        }
    }
}

extension SendInviteView {
    
    private var InviteTypeRow: some View {
        
        let event = vm.event
        
        return HStack {
            if let message = event.message {
                Text(event.message ?? "").font(.body(14))
            } else if let type = event.type {
                VStack(alignment: .leading, spacing: 6) {
                    Text(type.description.label).font(.body(18))
                    Text("Add a Message").foregroundStyle(.accent).font(.body(14))
                        .onTapGesture { vm.showMessageScreen.toggle()}
                }
            } else {
                Text("Type").font(.body(20, .bold))
            }
            
            Spacer()
            
            Image((event.type == nil) && event.message == nil ? "InviteType" : "EditButton")
                .onTapGesture {vm.showTypePopup.toggle()}
        }
    }
    
    private var InviteTimeRow: some View {
        
        let time = vm.event.time
        
        let formattedTime: String = {
            guard let date = time else {return "Time"}
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d – h:mm a"
            return formatter.string(from: date)
        }()
        
        return HStack {
            if time != nil { Text(formattedTime).font(.body(18))
            } else {Text("Time").font(.body(20, .bold))}
            
            Spacer()
            
            Image(time == nil ? "InviteTime" : "EditButton")
                .onTapGesture {vm.showTimePopup.toggle()}
        }
    }
    
    private var InvitePlaceRow: some View {
        HStack {
            if let location = vm.event.location {
                VStack(alignment: .leading) {
                    Text(location.name ?? "")
                        .font(.body(18, .bold))
                    Text(location.placemark.title ?? "")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
            } else {
                Text("Place")
                    .font(.body(20, .bold))
            }
            Spacer()
            Image(vm.event.location == nil ? "InvitePlace" : "EditButton")
                .onTapGesture { vm.showMapView.toggle() }
        }
    }
}
