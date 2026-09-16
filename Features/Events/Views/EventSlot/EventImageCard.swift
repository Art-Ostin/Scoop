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
    @Environment(ResponseCoverPresenter.self) private var responseCover: ResponseCoverPresenter?
    @Environment(ViewEventFlight.self) private var viewEventFlight: ViewEventFlight?

    //Local view state
    @State private var page: Int = 0

    //The photo the calendar's View Event flight lands on, while one is on its way to this card
    private var landingPage: Int? { viewEventFlight?.landingPage(for: eventProfile.id, in: profileImages) }

    private var imageHidden: Bool {
        (responseCover?.eventImageHidden(eventProfile.id) ?? false) || (viewEventFlight?.imageHidden(eventProfile.id) ?? false)
    }

    var body: some View {
        VStack(spacing: 0) {
            //The source is the image INSIDE this card, not a card of its own:
            //eventCardBackground already elevates it (no second shadow), and
            //the card's clip squares the image's bottom edge (no radius there).
            //`page` is shared so the zoom opens on the photo the card shows,
            //and the card comes back on whichever photo the profile ended on.
            EventImageCarousel(images: profileImages, page: $page,
                               onProgress: { viewEventFlight?.reportPad(progress: $0, id: eventProfile.id) })
                .zoomTransition(images: profileImages,
                                page: $page,
                                showsCardShadow: false,
                                bottomCornerRadius: 0) {
                    profileView
                }
                //The accept and View Event flights' landing pad: hidden while the flown copy
                //owns the pixels (the hand-off un-hides it beneath the still-opaque copy), and
                //its global rect reported live so the flight knows where to land.
                .opacity(imageHidden ? 0 : 1)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
                    responseCover?.reportEventImageFrame($0, id: eventProfile.id)
                    viewEventFlight?.reportPad(frame: $0, id: eventProfile.id)
                }
            timerSection
                .padding(.vertical, 6)
        }
        .clipShape(.rect(cornerRadius: CornerRadius.image))
        .eventCardBackground()
        .onChange(of: profileImages, initial: true) { viewEventFlight?.reportPad(images: $1, id: eventProfile.id) }
        .task(id: landingPage) { await turnToLandingPage() }
    }
}

//The calendar's View Event flight: the card turns to the popup's photo before it lands
extension EventImageCard {

    //A `.scrollPosition` write only moves a carousel that is live in a window, and the Events tab is put back in
    //the window partway through the flight — so the turn is re-asserted until the carousel reports it
    private func turnToLandingPage() async {
        var turning = false
        //However the turn ends — taken, or its flight gone before the carousel took it — `page` is left on what the
        //carousel shows, or the zoom would open on a photo the card isn't showing
        defer { if turning { settlePageOnPixels() } }
        while let target = landingPage, !Task.isCancelled {
            turning = true
            let progress = viewEventFlight?.padProgress(for: eventProfile.id)
            if let progress, abs(progress - Double(target)) < 0.01 { return }
            if page == target, let progress {
                setPage(Int(progress.rounded())) //A real change, so the write after it is one too
                do { try await Task.sleep(for: ViewEventFlightMotion.commitBeat) } catch { return }
            }
            setPage(target)
            do { try await Task.sleep(for: ViewEventFlightMotion.pageRecheck) } catch { return }
        }
    }

    private func settlePageOnPixels() {
        guard let progress = viewEventFlight?.padProgress(for: eventProfile.id) else { return }
        let shown = Int(progress.rounded())
        if page != shown { setPage(shown) }
    }

    private func setPage(_ index: Int) {
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) { page = index }
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
    var onProgress: (Double) -> Void = { _ in } //Where it sits, in pages: the View Event flight lands only on a settled page

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
        .onChange(of: scrollProgress, initial: true) { onProgress($1) }
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
