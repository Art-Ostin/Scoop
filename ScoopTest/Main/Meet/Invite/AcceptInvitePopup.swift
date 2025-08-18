//
//  InviteAcceptPopup.swift
//  ScoopTest
//
//  Created by Art Ostin on 14/08/2025.
//

import SwiftUI

struct AcceptInvitePopup: View {
    
    @Environment(\.tabSelection) private var tabSelection
    @State var showAlert: Bool = false
    
    let image: UIImage
    let event: UserEvent
    let vm: SendInviteViewModel
    var onDismiss : () -> Void
    
    
    init(vm: SendInviteViewModel, image: UIImage, onDismiss: @escaping () -> Void = {}) {
        self.vm = State(initialValue: vm)
        self.onDismiss = onDismiss
    }

    var body: some View {
        
        VStack(spacing: 32) {
            
            HStack() {
                CirclePhoto(image: image ?? UIImage())
                
                Text("Meet \(vm.event.otherUserName ?? "")")
                    .font(.title(24, .bold))
                
                if event.message != nil {
                    Spacer()
                }
            }
            
            EventFormatter(event: vm.event)
            
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
                .padding(20)
        }
        .padding(.horizontal, 24)
        .alert("Event Commitment", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) {}
            Button ("I Understand") {
                Task {
                    try? await vm.acceptInvite()
                    tabSelection.wrappedValue = 1
                    onDismiss()
                }
            }
        } message: {
            Text("If you dont show, you'll be blocked from Scoop")
        }.tint(.blue)
    }
}
