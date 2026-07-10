//
//  BackgroundBlur.swift
//  Scoop
//
//  Created by Art Ostin on 10/06/2026.
//

import SwiftUI

//Soft blurred-image halo revealed behind text overlaid on a photo (card names/details).
struct BackgroundBlur: View {

    //Halo metrics shared with SendInviteFlight, which re-creates this treatment on animated anchors.
    //TODO: flight pass — the flight blurs at `imageBlurRadius` while this body blurs at 40,
    //and the mask insets differ; reconcile so the settle handoff is identical.
    static let imageBlurRadius: CGFloat = 22
    static let haloCornerRadius: CGFloat = 12
    static let haloWidthOutset: CGFloat = 4
    static let haloBlurRadius: CGFloat = 4

    
    let image: UIImage
    // Label frames to reveal blur behind — in the base image's coordinate space.
    let frames: [CGRect]

    var body: some View {
        // Color.clear adopts the proposed size exactly, so the mask's coordinate
        // space matches the base image the frames were measured against.
        Color.clear
            .overlay { Image(uiImage: image).resizable().scaledToFill() }
            .blur(radius: 40)
            .mask { mask } //The stencil: which bits of the blurred image to show.
            .allowsHitTesting(false)
    }

    private var mask: some View {
        ZStack {
            ForEach(frames.indices, id: \.self) { index in
                let frame = frames[index]
                let dy = min(8, max((frame.height - 12) / 2, 0)) //Tighten the halo but never below a certain point
                let rect = frame.insetBy(dx: 0, dy: dy)
                
                
                RoundedRectangle(cornerRadius: Self.haloCornerRadius)
                    .frame(width: max(rect.width, 0), height: max(rect.height, 0))
                    .position(x: rect.midX, y: rect.midY)
                    .blur(radius: Self.haloBlurRadius) //Feather the halo edge so the reveal fades out.
                    .offset(y: 2) //Frame tops sit at ascender height ('L', 'T'); nudge the halo down.
            }
        }
    }
}
