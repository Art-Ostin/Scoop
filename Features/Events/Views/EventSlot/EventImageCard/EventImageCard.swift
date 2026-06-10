//
//  EventImageCard.swift
//  Scoop Test
//
//  Created by Art Ostin on 10/06/2026.
//

import SwiftUI

struct EventImageCard: View {
    @Bindable var ui: EventUIState
    let eventProfile: EventProfile
    let imageSize: CGFloat
    
    let userImage: UIImage
    let targetTime: Date
    
    
    var body: some View {
        VStack(spacing: 10) {
            EventImage(ui: ui, eventProfile: eventProfile, imageSize: imageSize)
            
            EventTimer(userImage: userImage, profileImage: eventProfile.image ?? UIImage(), targetTime: targetTime)
        }
        .padding([.top, .horizontal], 4)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCanvas)
                .eventCardShadowBackground()
        )
    }
}
