//
//  RespondAcceptContainer.swift
//  Scoop
//
//  Created by Art Ostin on 21/03/2026.
//

import SwiftUI

struct RespondAcceptContainer: View {
    
    @Bindable var ui: ProfileUIState
    
    @State var isFlipped: Bool = false
    let event: UserEvent
    let image: UIImage
    let name: String
    
    let onAccept: (UserEvent) -> ()
    let onDecline: (UserEvent) -> ()

    
    var body: some View {
        
        ZStack {
            if !isFlipped {
                RespondCard(ui: ui, isFlipped: $isFlipped, event: event, image: image, name: name) { event in
                    onAccept(event)
                } onDecline: { event in
                    onDecline(event)
                }
                .zIndex(0)
            } else {
                RespondDetailsCard(event: event, isFlipped: $isFlipped, image: image)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y:1, z:0))
        .animation(.easeInOut, value: isFlipped)
        .overlay(alignment: .bottom) {
            if false { //Not using at the moment, might use later
                Text("You’ll never know if if they’re for you unless you meet them!")
                    .font(.title(14, .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 72)
                    .offset(y: 120)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.grayText)
            }
        }
    }
    
    
    @ViewBuilder
    private var infoButton: some View {
        if isFlipped {
            
        } else {
            TabInfoButton(showScreen: $isFlipped)
                .scaleEffect(0.9)
                .offset(x: -24, y: -20)
        }
    }
    
    private var extraMessage: some View {
        Text("You’ll never know if if they’re for you unless you meet them!")
            .font(.title(14, .bold))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 72)
            .offset(y: 120)
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.grayText)
    }
}
