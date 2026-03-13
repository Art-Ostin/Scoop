//
//  AcceptInviteView.swift
//  Scoop
//
//  Created by Art Ostin on 15/02/2026.
//

import SwiftUI

struct AcceptInviteView: View {
    
    
    @Binding var showInvite: Bool
    
    let profileModel: ProfileModel
    
    let event: UserEvent
    
    let onAccept: (UserEvent) -> ()
    
    let onDecline: (UserEvent) -> ()
    
    @State var showInfoScreen: Bool = false
    
    var body: some View {
        
        ZStack {
            CustomScreenCover {showInvite = false }
            
            VStack(alignment: .center, spacing: 24) {
                HStack(spacing: 8) {
                    if let image = profileModel.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    }
                    Text("Meet \(profileModel.profile.name)")
                        .font(.body(22, .bold))
                }
                
                VStack(spacing: 16) {
                    Text( "\(EventFormatting.expandedDate(event.proposedTimes.dates.first?.date ?? Date()) ) · \(EventFormatting.hourTime(event.proposedTimes.dates.first?.date ?? Date())) ")
                        .font(.body(20, .medium))
                    
                    if let message = event.message, !message.isEmpty {
                        Text(message)
                            .font(.body(14, .italic))
                            .lineSpacing(5)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.grayText)
                    }
                    
                    typeAndPlace
                }
                ActionButton(text: "Accept", isInvite: true, cornerRadius: 16) { onAccept(event) }
            }
            .padding(22)
            .padding(.bottom, 8)
            .frame(width: 340)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .foregroundStyle(Color.background)
                    .shadow(color: .appGreen.opacity(0.15), radius: 4, y: 2)
            )
            .stroke(24, lineWidth: 1, color: Color.grayPlaceholder)
            .overlay(alignment: .topTrailing) {
                TabInfoButton(showScreen: $showInfoScreen)
                    .scaleEffect(0.9)
                    .offset(x: -12, y: -48)
            }
            .offset(y: 12)
        }
        .sheet(isPresented: $showInfoScreen) {
            Text("Info Screen")
        }
        .overlay(alignment: .topLeading) {
            MinimalistButton(text: "Decline") {
                onDecline(event)
            }
            .padding(.top, 36)
            .padding(.horizontal, 20)
        }
        .toolbar(.hidden, for: .tabBar) // native TabView tab bar
        .tabBarHidden(true)
    }
}

extension AcceptInviteView {
    
    
    private var typeAndPlace: some View {
        HStack(spacing: 8) {
            Text("\(event.type.description.emoji ?? "")  \(event.type.description.label) ")
                .font(.body(16, .medium))
            
            Button {
                MapsRouter.openGoogleMaps(item: event.location.mapItem, withDirections: false)
            } label: {
                Text(event.location.name ?? "Location")
                    .font(.body(20, .bold))
                    .foregroundStyle(Color.appGreen)
            }
        }
    }
}

