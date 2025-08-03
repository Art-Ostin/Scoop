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
                    ActionButton(isValid: InviteIsValid, text: "Confirm & Send", onTap: {
                        profileVM.showInvite.toggle()
                        profileVM.inviteSent = true
                    })
                }
            }
            if vm.showTypePopup {
                SelectTypeView(vm: $vm)
                    .offset(y: 72)
            }
            
            if vm.showTimePopup {
                SelectTimeView(vm: $vm)
                    .offset(y: 164)
            }
        }
        .sheet(isPresented: $vm.showMessageScreen) {
//            InviteAddMessageView(vm: $vm)
        }
        .fullScreenCover(isPresented: $vm.showMapView) {
//            MapView(vm2: $vm)
        }
    }
    
    
    
    
    
    private var InviteIsValid: Bool {
        return (vm.event.type != nil || vm.event.message != nil) && vm.event.time != nil && vm.event.location != nil
    }
    
    
    
    
    
    struct Event {
        var profile: UserProfile
        var profile2: UserProfile
        var type: EventType?
        var time: Date?
        var location: MKMapItem?
        var message: String?
    }
    
    
}

extension SendInviteView {
    
    private var InviteTypeRow: some View {
        
        let event = vm.event
        
        return HStack {
            if let _ = event.message {
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
            
            if vm.showTimePopup {
                Image(systemName: "chevron.down")
                    .onTapGesture {vm.showTimePopup.toggle() }
            } else {
                Image(time == nil ? "InviteTime" : "EditButton")
                    .onTapGesture {vm.showTimePopup.toggle() }
                }
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
//    struct Event {
//        var profile: UserProfile
//        var profile2: UserProfile
//        var type: EventType?
//        var time: Date?
//        var location: MKMapItem?
//        var message: String?
//    }
//    
//    private func isValidInvite() -> Bool {
//        guard
//            vm.event.type.description || (vm.event.message != nil)
//        
//
//            !vm.event.message.isEmpty else { return false }
//        return true
//    }
}
