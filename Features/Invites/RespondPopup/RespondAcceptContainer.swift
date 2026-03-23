//
//  RespondAcceptContainer.swift
//  Scoop
//
//  Created by Art Ostin on 21/03/2026.
//

import SwiftUI

struct RespondAcceptContainer: View {
    
    @Bindable var ui: ProfileUIState
    @Bindable var vm: TimeAndPlaceViewModel
    
    @State var isFlipped: Bool = false
    let event: UserEvent
    let image: UIImage
    let name: String
    
    let onAccept: (UserEvent) -> ()
    let onDecline: (UserEvent) -> ()

    
    var body: some View {
        
        ZStack {
            if !isFlipped {
                RespondCard(vm: vm, ui: ui, isFlipped: $isFlipped, event: event, image: image, name: name) { event in
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
    }
}
