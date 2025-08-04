//
//  SendInviteView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.

import SwiftUI
import MapKit



struct SendInviteView: View {
    
    @Binding var profileVM: ProfileViewModel
    @State var vm: SendInviteViewModel
    
    @FocusState var isFocused: Bool
    
    init(profile1: UserProfile, profile2: UserProfile, profileVM: Binding<ProfileViewModel>) {
        self._vm = State(initialValue: SendInviteViewModel(profile1: profile1, profile2: profile2))
        self._profileVM = profileVM
    }
    
    var body: some View {
        
        ZStack {
            PopupTemplate(profileImage: InviteImage, title: "Meet \(vm.event.profile2.name ?? "")") {
                VStack(spacing: 30) {
                    InviteTypeRow
                    Divider()
                    InviteTimeRow
                    Divider()
                    InvitePlaceRow
                    ActionButton(isValid: InviteIsValid, text: "Confirm & Send", onTap: {
                        profileVM.showInvite.toggle()
                        profileVM.inviteSent = true
                        Task {
                            try? await  vm.manager.createEvent(event: vm.event)

                        }
                    })
                }
            }
            if vm.showTypePopup {
                SelectTypeView(vm: $vm)
                    .offset(y: 96)
            }
            if vm.showTimePopup {
                SelectTimeView(vm: $vm)
                    .offset(y: 164)
            }
        }
        .sheet(isPresented: $vm.showMessageScreen) {
            InviteAddMessageView(vm: $vm)
        }
        .fullScreenCover(isPresented: $vm.showMapView) {
            MapView(vm2: $vm)
        }
    }
    private var InviteIsValid: Bool {
        return (vm.event.type != nil || vm.event.message != nil) && vm.event.time != nil && vm.event.location != nil
    }
}

extension SendInviteView {
    
    private var InviteTypeRow: some View {
        
        let event = vm.event
        
        return HStack {
            
            if let type = event.type?.description.label, let message = event.message {
                (
                    Text((event.type == .writeAMessage) ? "" : "\(type): ")
                        .font(.body(16, .bold))
                    + Text(" " + message)
                        .font(.body(12, .italic))
                        .foregroundStyle(Color.grayText)
                )
            } else if let type = event.type?.description.label {
                VStack(alignment: .leading, spacing: 6) {
                    Text(type).font(.body(18))
                    Text("Add a Message").foregroundStyle(.accent).font(.body(14))
                        .onTapGesture {
                            vm.showTypePopup = false
                            vm.showMessageScreen.toggle()
                        }
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
                    Text(location.address ?? "")
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
    private var InviteImage: CirclePhoto? {
        if let urlString = vm.event.profile2.imagePathURL?[0],
           let url = URL(string: urlString) {
            return CirclePhoto(url: url)
        } else {return nil}
    }
}
