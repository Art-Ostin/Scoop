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
            
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    HStack(alignment: .center, spacing: 8) {
                        if let image = profileModel.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }
                        Text("Meet \(profileModel.profile.name)")
                            .font(.body(24, .bold))
                    }
                    
                    
                    Text("\(event.type.description.emoji ?? "")  \(event.type.description.label) ")
                        .font(.body(16, .medium))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .center, spacing: 16) {
                    Text( "\(EventFormatting.expandedDate(event.proposedTimes.dates.first?.date ?? Date()) ) · \(EventFormatting.hourTime(event.proposedTimes.dates.first?.date ?? Date())) ")
                        .font(.body(20, .medium))
                    
                    Button {
                        
                    } label: {
                        Text(event.location.name ?? "Location")
                            .font(.body(20, .bold))
                            .foregroundStyle(Color.appGreen)
                    }
                    
                    ActionButton(text: "Accept", isInvite: true, cornerRadius: 16) { onAccept(event) }
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(Color(red: 0.32, green: 0.32, blue: 0.32))
                .font(.body(16, .regular))
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
        }
        .sheet(isPresented: $showInfoScreen) {
            Text("Info Screen")
        }
        .overlay(alignment: .topLeading) {
            MinimalistButton(text: "Decline") {
                onDecline(event)
            }
            .padding(.top, 144)
            .padding(.horizontal, 48)
        }
        .toolbar(.hidden, for: .tabBar) // native TabView tab bar
        .tabBarHidden(true)
    }
}

extension AcceptInviteView {
    
    
}



/*
 let eventTime = "\(EventFormatting.expandedDate(acceptedTime)) · \(EventFormatting.hourTime(acceptedTime))"

 */
