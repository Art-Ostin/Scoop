//
//  ChatHeaderBar.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

struct ChatHeaderBar: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var profileOpen: ProfileModel?
    @Binding var dismissOffset: CGFloat?
    
    @State var detailsOpen = false
    @Namespace private var ns
    
    let profileModel: ProfileModel
    let isEvent: Bool
    var isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        HStack {
            if profileOpen != nil {
                profileCloseButton
            } else {
                closeButtonMain
            }
            Spacer()
            profileButton
        }
        .padding(.horizontal)
        .onPreferenceChange(OpenDetails.self) { isDetailsOpen in
            detailsOpen = isDetailsOpen
        }
        .animation(.easeInOut(duration: 0.2), value: profileOpen)
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
    
    private var profileButton: some View {
        Button(action: openProfile) {
            HStack(spacing: 6) {
                if let image = profileModel.image {
                    CirclePhoto(image: image, showShadow: false)
                        .scaleEffect(0.9)
                }
                
                Text(profileModel.profile.name)
                    .font(.body(16, .bold))
            }
            .padding(.vertical, 3)
            .padding(.leading, 4)
            .padding(.trailing, 8)
            .glassIfAvailable(RoundedRectangle(cornerRadius: 24), isClear: false)
            .opacity(
                withAnimation(.easeInOut(duration: 0.1)) {
                    profileOpen != nil ? 0 : 1
                })
        }
    }
    
    private var profileCloseButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: isEvent ? "xmark" : "chevron.left")
                .matchedGeometryEffect(id: "button", in: ns)
                .font(.body(16, .bold))
                .contentShape(Rectangle())
                .foregroundStyle(Color.black)
                .padding(6)
                .glassIfAvailable(Circle(), isClear: true)
                .offset(y: -14)
                .opacity(detailsOpen ? 0 : 1)
        }
    }
    
    private func openProfile() {
        isFocused.wrappedValue = false
        dismissOffset = nil
        withAnimation(.easeInOut(duration: 0.2)) {profileOpen = profileModel}
    }
}
