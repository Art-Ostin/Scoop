//
//  EventImageCard.swift
//  Scoop
//
//  Created by Art Ostin on 10/06/2026.
//

import SwiftUI

struct EventImageCard: View {
    @Bindable var ui: EventsUIState
    let eventProfile: EventProfile
    let imageSize: CGFloat
    
    let userImage: UIImage
    let targetTime: Date
    
    
    var body: some View {
        VStack(spacing: 6) {
            EventImage(ui: ui, eventProfile: eventProfile, imageSize: imageSize)
            
            EventTimer(userImage: userImage, profileImage: eventProfile.image ?? UIImage(), targetTime: targetTime)
        }
        .padding([.top, .horizontal], 6)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.appCanvas)
                .eventCardShadowBackground()
        )
    }
}
