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
    var profileModel: ProfileModel
    var onSubmit : () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {showAlert = false }
            
            VStack(spacing: 32) {
                HStack() {
                    CirclePhoto(image: profileModel.image ?? UIImage())
                    
                    Text("Meet \(profileModel.profile.name)")
                        .font(.title(24, .bold))
                    
                    if profileModel.event?.message != nil {
                        Spacer()
                    }
                }
                if let event = profileModel.event, let time = event.acceptedTime {
                    EventFormatter(time: time, type: event.type, message: event.message, place: event.location)
                }
                ActionButton(text: "Accept", isInvite: true, cornerRadius: 12) { showAlert.toggle() }
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
                Button {
                    showAlert = false
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.black)
                        .font(.body(17, .bold))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 24)
            .alert("Event Commitment", isPresented: $showAlert) {
                Button("Cancel", role: .cancel) {}
                Button ("I Understand") {
                    onSubmit()
                }
            } message: {
                Text("If you dont show, you'll be blocked from Scoop")
            }.tint(.blue)
        }
    }
}
