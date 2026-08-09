//
//  ImageElements.swift
//  Scoop
//
//  Created by Art Ostin on 09/07/2026.
//

import SwiftUI
import Glur


enum AppImageType {case meet, invite}

struct AppImage: View {

    let image: UIImage
    let type: AppImageType
    
    var aspectRatio: CGFloat { type == .meet ? 1/1.2 : 1/1.55}
        
    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: 20))
            .containerRelativeFrame(.horizontal) { length, _ in
                return max(length - 16 * 2, 0)
            }//No padding but this method so overlay content works
    }
}

//One carousel page: fill-crop, softened bottom, sharp edges. Shared between the live pager
//and the invite flight's static covers so the swap between them is pixel-identical.
struct InvitePagePhoto: View {

    //Glur drops its whole layerEffect at exactly 0, and that structural swap flashes the page
    //mid-morph. A hair above zero keeps the shader mounted through the screen change: its
    //64-tap Gaussian collapses onto the centre sample, so it reads as untouched artwork.
    private static let blurOff: CGFloat = 0.01
    private static let blurOn: CGFloat = 14

    let image: UIImage
    let blursBottom: Bool

    var body: some View {
        Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .glur(radius: blursBottom ? Self.blurOn : Self.blurOff, offset: 0.85, interpolation: 0.3, direction: .down, noise: 0)
            .mask {
                VStack(spacing: 0) {
                    Rectangle() // Left, right and top stay razor sharp.
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 2)
                }
            }
            .clipped() //scaledToFill overflows the cell
    }
}

struct InviteCarousel: View {

    //Injected Properties
    let images: [UIImage]
    let isCompact: Bool
    let blursBottom: Bool

    //The invite flight frames this carousel itself; aspect sizing would fight the animated frame
    var fillsFrame: Bool = false

    //The flight snaps the pager home under a cover before resizing it
    var position: Binding<ScrollPosition>? = nil

    @Binding var scrollProgress: Double

    private var ratio: CGFloat {
        (isCompact ? AspectRatio.confirmInviteImage : .invitedImage).ratio
    }

    @ViewBuilder
    var body: some View {
        if fillsFrame {
            pager
        } else {
            pager
                .aspectRatio(ratio, contentMode: .fit) //Sizes the greedy pager to the image shape
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var pager: some View {
        HorizontalScrollView(progress: $scrollProgress, position: position) {
            ForEach(images, id: \.self) { image in
                InvitePagePhoto(image: image, blursBottom: blursBottom)
                    .containerRelativeFrame(.horizontal)
            }
        }
    }
}


struct SmallImage: View {
    let image: UIImage
    let size: CGFloat
    
    var radius: CGFloat = CornerRadius.smallImage
    var isCircle: Bool = false
        
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(.rect(
                cornerRadius: isCircle ? size / 2 : radius,
                style: isCircle ? .circular : .continuous
            ))
    }
}


struct InvitePageIndicator: View {
    let count: Int
    let progress: Double

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<count, id: \.self) { index in
                let closeness = max(0, 1 - abs(progress - Double(index)))

                Capsule()
                    .fill(Color.border)
                    .overlay {
                        Capsule()
                            .fill(Color.textSecondary)
                            .opacity(closeness)
                    }
                    .frame(width: 3 + 2 * CGFloat(closeness), height: 3)
            }
        }
        .frame(width: count > 0 ? 5 + CGFloat(count - 1) * 8 : 0, height: 3)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
