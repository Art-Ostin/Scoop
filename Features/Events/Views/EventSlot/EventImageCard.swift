//
//  EventImageCard.swift
//  Scoop
//
//  Created by Art Ostin on 10/06/2026.
//

import SwiftUI

struct EventImageCard: View {

    //Injected
    let eventProfile: EventProfile
    let defaults: DefaultsManaging
    let imageLoader: ImageLoading
    
    
    let profileImages: [UIImage]
    let userImage: UIImage?
    let targetTime: Date

    //Local view state
    @State private var page: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            //The source is the image INSIDE this card, not a card of its own:
            //eventCardBackground already elevates it (no second shadow), and
            //the card's clip squares the image's bottom edge (no radius there).
            //`page` is shared so the zoom opens on the photo the card shows,
            //and the card comes back on whichever photo the profile ended on.
            EventImageCarousel(images: profileImages, page: $page)
                .zoomTransition(images: profileImages,
                                page: $page,
                                showsCardShadow: false,
                                bottomCornerRadius: 0) {
                    profileView
                }
            timerSection
                .padding(.vertical, 6)
        }
        .clipShape(.rect(cornerRadius: CornerRadius.image))
        .eventCardBackground()
    }
}


extension EventImageCard {
    
    private var profileView: some View {
        ProfileContainer(vm: profileVM, profileImages: profileImages, mode: .viewProfile)
    }
    
    private var profileVM: ProfileViewModel {
        ProfileViewModel(
            profile: eventProfile.profile,
            event: eventProfile.event,
            imageLoader: imageLoader,
            defaults: defaults,
            images: profileImages
        )
    }
    
    
    
    
    
    
}

extension EventImageCard {
    
    private var timerSection: some View {
        HStack(spacing: Spacing.lg) {
            photoOverlap
            clockView
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.md)
    }
    
    var photoOverlap: some View {
        ZStack(alignment: .topLeading) {
            SmallImage(image: userImage ?? UIImage(), size: 38, isCircle: true)
                .circleStroke(lineWidth: 1.5, color: .appCanvas)
            
            SmallImage(image: profileImages.first ?? UIImage(), size: 38, isCircle: true)
                .circleStroke(lineWidth: 1.5, color: .appCanvas)
                .offset(x: 18, y: 15)
        }
        .frame(width: 60, height: 56, alignment: .topLeading)
    }
}

//All Logic relating to the clock view
extension EventImageCard {
    
    private var clockView: some View {
        CountdownTimer(targetTime: targetTime) { timeRemaining in
            let days = timeRemaining.day ?? 0
            let hours = timeRemaining.hour ?? 0
            let minutes = timeRemaining.minute ?? 0
            let seconds = timeRemaining.second ?? 0
            
            HStack(alignment: .top) {
                timeSection(time: days, type: "DAYS")
                timeDivider
                timeSection(time: hours, type: "HRS")
                timeDivider
                timeSection(time: minutes, type: "MIN")
                timeDivider
                timeSection(time: seconds, type: "SEC")
            }
        }
    }

    private func timeSection(time: Int, type: String) -> some View {
        VStack(spacing: 0) {
            Text("\(time)")
                .font(.title(28))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .foregroundStyle(Color.textAccent)
            
            Text(type)
                .foregroundStyle(Color.textPlaceholder)
                .font(.title(8, .medium))
        }
        .frame(width: 37, height: 21)
    }

    private var timeDivider: some View {
        Capsule()
            .fill(Color.fillGray)
            .frame(width: 0.85, height: 14)
            .offset(y: -4)
            .frame(maxWidth: .infinity)
    }
}


struct EventImageCarousel: View {

    //Injected
    let images: [UIImage]
    @Binding var page: Int

    //Local view state
    @State private var scrollProgress: Double = 0

    //The settled page, as .scrollPosition reports it: nil mid-scroll, which
    //leaves the card's page on the last one it landed on.
    private var settledPage: Binding<Int?> {
        Binding(get: { page }, set: { if let new = $0 { page = new } })
    }

    var body: some View {

        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                    profileImage(image: image)
                }
            }
            .scrollTargetLayout()
        }
        .overlay(alignment: .bottom) {
            pageIndicator
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        //Two-way: reports the page the zoom transition opens on, and takes
        //the page the profile ended on while the card is hidden mid-flight.
        .scrollPosition(id: settledPage)
        .trackScrollProgress(scrollProgress: $scrollProgress)
    }

    private func profileImage(image: UIImage) -> some View {
        Color.clear
            .aspectRatio(1/1.02, contentMode: .fit)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .containerRelativeFrame(.horizontal)
    }
    
    
    private var pageIndicator: some View {
        ImagePageIndicator(count: images.count, progress: scrollProgress, activeColor: .white)
            .scaleEffect(0.7, anchor: .trailing)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xs)
    }
}
