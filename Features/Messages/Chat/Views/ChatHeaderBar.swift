//
//  ChatHeaderBar.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

struct ChatHeaderBar: View {
    
    //1. To (1) Close mesage container and (2) UserProfile
    @Environment(\.dismiss) private var dismiss
    @Binding var profileOpen: Bool
    
    //2. Parameters to pass in for the header bar for view
    let image: UIImage
    let name: String
    let isEvent: Bool
    
    var body: some View {
        HStack {
            closeButton
            Spacer()
        }
        .padding(.horizontal)
    }
}

extension ChatHeaderBar {
        
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: isEvent ? "xmark" : "chevron.left")
                .font(.body(profileOpen ? 16 : 18, .bold))
                .foregroundStyle(Color.black)
                .padding(profileOpen ? 6 : 12)
                .hoverButton(Circle())
        }
    }
    
    private var profileButton: some View {
        Button {
            profileOpen = true
        } label: {
            HStack(spacing: 6) {
                CirclePhoto(image: image, showShadow: false)
                    .scaleEffect(0.9)
                
                Text(name)
                    .font(.body(16, .bold))
            }
            .padding(.vertical, 3)
            .padding(.leading, 4)
            .padding(.trailing, 8)
            .hoverButton(RoundedRectangle(cornerRadius: 24))
            .opacity(profileOpen ? 0 : 1)
        }
    }
}


/*
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
             .hoverButton(Circle())
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
             .padding(6)
             .hoverButton(Circle())
             .offset(y: -14)
     }
 }
 
 
 
 struct ProfileButton: View {
     
     //1.
     @Binding var openProfile: UserProfile?
     
     let image: UIImage
     let profile: UserProfile
     
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
             .hoverButton(RoundedRectangle(cornerRadius: 24))
         }
     }
 }
 
 */
