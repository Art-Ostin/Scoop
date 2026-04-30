//
//  ChatHeaderBar.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

struct ChatHeaderBar: View {

    @Environment(\.dismiss) private var dismiss

    @Binding var isProfileOpen: UserProfile?

    @State var detailsOpen = false
    @Namespace private var ns

    let profile: UserProfile
    let image: UIImage

    let isEvent: Bool
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack {
            closeButtonMain
            Spacer()
            ProfileButton(image: image, profile: profile, isProfileOpen: $isProfileOpen, isFocused: isFocused)
        }
        .padding(.horizontal)
        .onPreferenceChange(OpenDetails.self) { isDetailsOpen in
            detailsOpen = isDetailsOpen
        }
        .animation(.easeInOut(duration: 0.2), value: isProfileOpen)
    }
}

extension ChatHeaderBar {
    
    private var closeButtonMain: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: isEvent ? "xmark" : "chevron.left")
                .matchedGeometryEffect(id: "button", in: ns)
                .font(.body(18, .bold))
                .contentShape(Rectangle())
                .foregroundStyle(Color.black)
                .padding(12)
                .glassIfAvailable(Circle(), isClear: false)
        }
    }
    
    

    
    
}


struct ProfileButton: View {

    let image: UIImage
    let profile: UserProfile

    @Binding var isProfileOpen: UserProfile?
    var isFocused: FocusState<Bool>.Binding


    var body: some View {
        Button(action: openProfile) {
            HStack(spacing: 6) {
                CirclePhoto(image: image, showShadow: false)
                    .scaleEffect(0.9)

                Text(profile.name)
                    .font(.body(16, .bold))
            }
            .padding(.vertical, 3)
            .padding(.leading, 4)
            .padding(.trailing, 8)
            .glassIfAvailable(RoundedRectangle(cornerRadius: 24), isClear: false)
            .opacity(
                withAnimation(.easeInOut(duration: 0.1)) {
                    isProfileOpen != nil ? 0 : 1
                })
        }
    }

    private func openProfile() {
        isFocused.wrappedValue = false
        isProfileOpen = profile
    }
}

/*
 
 private var profileButton: some View {
     Button(action: openProfile) {
         HStack(spacing: 6) {
             CirclePhoto(image: image, showShadow: false)
                 .scaleEffect(0.9)
             
             Text(profile.name)
                 .font(.body(16, .bold))
         }
         .padding(.vertical, 3)
         .padding(.leading, 4)
         .padding(.trailing, 8)
         .glassIfAvailable(RoundedRectangle(cornerRadius: 24), isClear: false)
         .opacity(
             withAnimation(.easeInOut(duration: 0.1)) {
                 isProfileOpen != nil ? 0 : 1
             })
     }
 }
 
 */
