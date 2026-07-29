//
//  NewInviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 06/06/2026.
//

import SwiftUI
import Glur


struct InviteCard: View {
    
    //Injected Parameters
    let image: UIImage
    let name: String
    
    @Binding var draft: RespondDraft
    
    let openInvite: () -> ()
    
    //Local Parameters
    @State private var timePopupOpen = false
    
    var body: some View {
        AppImage(image: image, type: .invite)
            .modifier(BlurAndGradientBackground())
            .overlay(alignment: .bottom) {overlayText}
    }
}

//Title And Type
extension InviteCard {
    
    private var overlayText: some View {
        VStack(alignment: .leading, spacing: 24) {
            nameTitle
                .opacityPop(visible: !timePopupOpen)
            RespondTimeLine(draft: $draft, timePopupOpen: $timePopupOpen)
            placeRow
                .opacityPop(visible: !timePopupOpen)
        }
        .overlay(alignment: .topTrailing) { typeButton}
        .frame(maxWidth: .infinity, maxHeight: .infinity,  alignment: .bottomLeading)
        .overlay(alignment: .bottomTrailing) {InviteButton{openInvite()} }
        .padding(24)
        .padding(.bottom, 5)
    }    
    
    
    private var typeButton: some View {
            HStack {
                Image("DrinkIcon")
                
                Text(draft.originalInvite.event.type.longTitle) //"Grab Drinks"
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.white)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .stroke(12, lineWidth: 1, color: .white.opacity(0.6))
            .scaleEffect(0.8, anchor: .bottomTrailing)
            .offset(y: -1.5)
            .opacityPop(visible: !timePopupOpen)
    }
}


//Time And Place
extension InviteCard {
    
    
    //Logic with the place
    private var placeRow: some View {
        let place = draft.originalInvite.event.location
        let text = place.name ?? place.address ?? "Location"
        
        return LineSection(image: .whiteMap, text: text, textColor: .white)
            .shrinkPress { MapsRouter.openGoogleMaps(item: place.mapItem)}
    }
}

struct BlurAndGradientBackground: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .glur(
                radius: 24,
                offset: 0.7,
                interpolation: 0.34,
                direction: .down,
                noise: 0
            )
            .overlay { blackGradient }
            .clipShape(.rect(cornerRadii: .init(top: 0, bottom: CornerRadius.image)))
    }
    
    private var blackGradient: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0), location: 0.65),
                .init(color: .black.opacity(0.6), location: 0.8),
                .init(color: .black.opacity(0.7), location: 0.85),
                .init(color: .black.opacity(0.9), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}
