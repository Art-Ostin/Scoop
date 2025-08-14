//
//  InviteAcceptPopup.swift
//  ScoopTest
//
//  Created by Art Ostin on 14/08/2025.
//

import SwiftUI

struct AcceptInvitePopup: View {
    
    let event: UserEvent
    var isMessage: Bool { event.message != nil }
    
    @Binding var vm: ProfileViewModel
    @Binding var image: UIImage?
    
    @State var showAlert: Bool = false
    
    var onDismiss : () -> Void
    
    init(vm: Binding<ProfileViewModel>, image: Binding<UIImage?>, event: UserEvent, onDismiss: @escaping () -> Void = {}) {
        self._vm = vm
        self._image = image
        self.event = event
        self.onDismiss = onDismiss
    }

    var body: some View {
        
        VStack(spacing: 32) {
            
            HStack() {
                CirclePhoto(image: image ?? UIImage())
                
                Text("Meet \(event.otherUserName ?? "")")
                    .font(.title(24, .bold))
                
                if isMessage {
                    Spacer()
                }
            }
            vm.dep.eventManager.eventFormatter(event: event)
            
            ActionButton(text: "Accept", isInvite: true, cornerRadius: 12) { showAlert.toggle()}
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.top, 24)
        .padding(.bottom, 32)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.background, in: RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(Color.grayBackground, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.25), radius: 50, x: 0, y: 10)
        .overlay(alignment: .topTrailing) {
            NavButton(.cross)
                .padding(20) //32
        }
        .padding(.horizontal, 24)
        .alert("Event Commitment", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) {}
            Button ("I Understand") {
                Task {
                    if let id = event.id {
                        try? await vm.dep.eventManager.updateStatus(eventId: id, to: .accepted)
                        onDismiss()
                    }
                }
            }
        } message : {
            Text("If you dont show, you'll be blocked from Scoop")
        }.tint(.blue)
    }
}
