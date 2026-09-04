//
//  ImageElements.swift
//  Scoop
//
//  Created by Art Ostin on 09/07/2026.
//

import SwiftUI


enum AppImageType {case meet, invite}

struct AppImage: View {

    let image: UIImage
    let type: AppImageType
    ///Widens the card past the type's own inset — a lone invite has no neighbour to leave room for
    var insetOverride: CGFloat? = nil

    var inset: CGFloat { insetOverride ?? (type == .meet ? Spacing.gutter : 9) } //Geometry: invite cards run 18pt apart, most of the gap a screen − 48 card leaves
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
                return max(length - inset * 2, 0)
            }//No padding but this method so overlay content works
    }
}

struct InvitePagePhoto: View {

    let image: UIImage
    var blurRect: CGRect? = nil

    var body: some View {
        photo
            .overlay { InvitePhotoBand(image: image, titleRect: blurRect) }
            .invitePhotoEdgeFade()
    }

    private var photo: some View {
        Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipped() //scaledToFill overflows the cell
    }
}

//The band treatment a page wears over its photo: the capsule frost behind the title and the foot
//at the bottom edge. ONE view for the live page and the event zoom's flying cover — the cover
//rides it in over the flight, and sharing the view is what keeps the two from drifting, so the
//landing hand-off has nothing to reveal.
struct InvitePhotoBand: View {

    private static let footHeight: CGFloat = 10
    private static let footBlur: CGFloat = 10

    let image: UIImage
    let titleRect: CGRect? //The title's glyph rect in this view's space; nil or empty = no frost

    var body: some View {
        Color.clear
            .blurBackground(rect: titleRect, image: image)
            .overlay { foot }
            .allowsHitTesting(false)
    }

    private var foot: some View {
        Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .padding(-Self.footBlur)
            }
            .blur(radius: Self.footBlur)
            .mask {
                VStack(spacing: 0) {
                    Color.clear
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: Self.footHeight)
                }
            }
    }
}

extension View {

    ///The page's bottom edge easing into the card's white; left, right and top stay razor sharp.
    ///`strength` lets the flying cover ride the fade in with the rest of the band (0 = a hard edge,
    ///the raw photo a source shows).
    func invitePhotoEdgeFade(strength: CGFloat = 1) -> some View {
        mask {
            VStack(spacing: 0) {
                Rectangle()
                LinearGradient(colors: [.black, .black.opacity(Double(1 - strength))],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 2) //Geometry: a hairline of softening, not a fade band
            }
        }
    }
}

struct InviteCarousel: View {

    //Injected Properties
    let images: [UIImage]
    let ratio: CGFloat

    var blurRect: CGRect? = nil

    //The invite flight frames this carousel itself; aspect sizing would fight the animated frame
    var fillsFrame: Bool = false

    //The flight snaps the pager home under a cover before resizing it
    var position: Binding<ScrollPosition>? = nil

    @Binding var scrollProgress: Double

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
                InvitePagePhoto(image: image, blurRect: blurRect)
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
