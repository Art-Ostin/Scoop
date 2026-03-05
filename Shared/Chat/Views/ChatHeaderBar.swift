//
//  ChatHeaderBar.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

struct ChatHeaderBar: View {
    
    
    
    
    
    
    var body: some View {
            HStack {
                if selectedProfile == nil {
                    closeButtonMain
                } else {
                    profileCloseButton
                        .opacity(detailsOpen ? 0 : 1)
                }
                Spacer()
                profileButton
            }
            .padding(.horizontal)
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
            }
        }
        
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
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedProfile != nil ? 0 : 1
                    }
                )
            }
            .contextMenu {
                Button(action: openProfile) {
                    Label("View profile", systemImage: "person.crop.circle")
                }
            }
        }
    }

private func openProfile() {
    isFocused = false
    dismissOffset = nil
    withAnimation(.easeInOut(duration: 0.2)) {
        selectedProfile = profileModel
    }
}

}

#Preview {
    ChatHeaderBar()
}
