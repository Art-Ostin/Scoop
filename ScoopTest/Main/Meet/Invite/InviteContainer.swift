//
//  SendInviteView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.

import SwiftUI
import MapKit



struct SendInviteView: View {
    
    @Binding var image: UIImage?
    
    @Binding var profileVM: ProfileViewModel
    @State var vm: SendInviteViewModel
    @FocusState var isFocused: Bool
    @State var showAlert: Bool = false
    
    let onDismiss: () -> Void
    
    init(recipient: UserProfile, dep: AppDependencies, profileVM: Binding<ProfileViewModel>, image: Binding<UIImage?>, onDismiss: @escaping () -> Void) {
        self._vm = State(initialValue: SendInviteViewModel(recipient: recipient, dep: dep))
        self._profileVM = profileVM
        self._image = image
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                HStack {
                    CirclePhoto(image: image ?? UIImage())
                    
                    Text("Meet \(vm.recipient.name ?? "")")
                        .font(.title(24))
                }
                InviteTypeRow
                Divider()
                InviteTimeRow
                Divider()
                InvitePlaceRow
                ActionButton(isValid: InviteIsValid, text: "Confirm & Send") {
                    showAlert.toggle()
                }
            }
            .frame(alignment: .top)
            .padding(.top, 24)
            .padding([.leading, .trailing, .bottom], 32)
            .frame(width: 365)
            .background(Color.background)
            .cornerRadius(30)
            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .inset(by: 0.5)
                    .stroke(Color.grayBackground, lineWidth: 0.5)
            )
            
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
        .alert("Event Commitment", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) {
                
                
            }
            Button ("I Understand") {
                Task {
                    try await vm.dep.eventManager.createEvent(event: vm.event)
                    onDismiss()
                    
                    let id = vm.dep.defaultsManager.getTwoDailyProfiles()
                    
                    let localId = profileVM.p.userId
                    
                    
                    
                    // Other code Once accepted.
                }
            }
        } message : {
            Text("If they accept and you do'nt show, you'll be blocked from Scoop")
        }.tint(.blue)
    }
    private var InviteIsValid: Bool {
        return (vm.event.type != nil || vm.event.message != nil) && vm.event.time != nil && vm.event.location != nil
    }
}

extension SendInviteView {
    
    private var InviteTypeRow: some View {
        
        let event = vm.event
        
        return HStack {
            
            if let type = event.type, let message = event.message {
                (
                    Text((event.type == "Write a message") ? "" : "\(type): ")
                        .font(.body(16, .bold))
                    + Text(" " + message)
                        .font(.body(12, .italic))
                        .foregroundStyle(Color.grayText)
                )
            } else if let type = event.type {
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
        
        return HStack {
            if time != nil { Text(vm.dep.eventManager.formatTime(date: time)).font(.body(18))
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
}

//    .alert("Event commitment", isPresented: $showAlert) {
//        Button("I understand") {
//            Task {
//                if let id = event.id {
//                    try? await vm.dep.eventManager.updateStatus(eventId: id, to: .accepted)
//                }
//            }
//        } .tint(.blue)
//        
//        Button("Cancel", role: .cancel) {}
//    } message: {
//        Text("If they accept & you don't show, you'll be blocked from Scoop")
//    }
