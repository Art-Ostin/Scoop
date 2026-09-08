//
//  RespondToInviteContainer.swift
//  Scoop
//
//  Created by Art Ostin on 02/09/2026.
//

import SwiftUI

struct RespondToInviteContainer: View {
    //Injected Properties
    @State var vm: RespondViewModel
    @State var ui = RespondUIState()
    @State var composeUI = ComposeInviteUIState()
    
    let images: [UIImage]
    let respond: (ProfileResponse) -> ()
    
    var type: ResponseType { vm.respondDraft.respondType }
    
    //Card content only: `.eventZoom` draws the backdrop, the white surface and the chevron around it
    var body: some View {
        VStack(spacing: 0) {
            imagePager
            eventInfoSection
            actionSection
                .padding(.top, 4)
        }
        .eventZoomChevronHidden(isConfirmNewEvent) //The confirm screen owns the corner with its back button
        .eventZoomDragLocked(composeUI.typePopupOpen || composeUI.timePopupOpen || ui.showAcceptAlert) //An open menu or alert owns the finger
        .sheet(isPresented: $composeUI.showInfoScreen) { Text("How it works")}
        .animation(.transition, value: composeUI.showConfirmScreen)
        .sheet(isPresented: $composeUI.showMessageScreen) {
            AddMessageView(message: $vm.respondDraft.newEvent.message,
                           isRespondMessage: false,
                           eventType: $vm.respondDraft.newEvent.type)
        }
        .fullScreenCover(isPresented: $composeUI.showMapView) {
            MapView(defaults: vm.defaults, eventLocation: $vm.respondDraft.newEvent.place)
        }
        //On the card's own plane, not inside it: the body is masked, so an in-place scrim stops at the card
        .eventZoomAlert(
            isPresented: $ui.showAcceptAlert,
            title: "\(selectedDayString)",
            emoji: "🧟",
            message: "Meeting \(vm.profile.name). Cancel up to 10 hours before — no-shows may be blocked.",
            cancelTitle: "Back",
            okTitle: "Confirm",
            offset: 36,
            onOK: { ctaAction() }, //Never cleared here: the plate leaves under the response cover, with the card (`BlurCoverMotion.coveredAt`)
            onCancel: {ui.showAcceptAlert = false}
        )
    }
}

//ImagePager logic
extension RespondToInviteContainer {
    var imagePager: some View {
        EventImagePager(images: images,
                        title: titleText,
                        showsPageDots: !isConfirmNewEvent,
                        titleVisible: !composeUI.delayedTimePopupOpen) //The time platter takes the band
        //Inert twins of both ride the flying cover and pop in on the flight's own ramp, with the band's
        //title and its frost; the real pieces take their pixels back at the landing, behind them, and
        //the cover's cut swaps the two
        .overlay(alignment: .topLeading) {
            backButton.eventZoomBandChrome(visible: isConfirmNewEvent, corner: .topLeading) { inertBackButton }
        }
        .overlay(alignment: .topTrailing) {
            topRow.eventZoomBandChrome(corner: .topTrailing) { inertTopRow }
        }
    }
    
    var titleText: String {
        switch type {
        case .originalInvite: "\(vm.profile.name)'s Invite"
        case .newTime: "Invite \(vm.profile.name)"
        case .newEvent: composeUI.showConfirmScreen == true ? "Confirm Invite" : "Invite \(vm.profile.name)"
        }
    }
    
    var backButton: some View {
        EventBackButton(showConfirmScreen: $composeUI.showConfirmScreen)
    }

    var topRow: some View {
        HStack(spacing: 6) {
            NewEventToggleButton(
                responseType: $vm.respondDraft.respondType,
                showConfirmScreen: $composeUI.showConfirmScreen
            )
        }
        .animation(.transition, value: isComposeInviteScreen)
    }

    //The two above, minus their buttons: what the event zoom flies in on the cover. Same labels, same
    //surfaces, same paddings — they hand off to the real pieces on identical pixels at the cover's cut
    var inertBackButton: some View {
        EventBackButton(showConfirmScreen: $composeUI.showConfirmScreen, inert: true)
    }

    var inertTopRow: some View {
        HStack(spacing: 6) {
            NewEventToggleButton(
                responseType: $vm.respondDraft.respondType,
                showConfirmScreen: $composeUI.showConfirmScreen,
                inert: true
            )
        }
    }
    
    var isComposeInviteScreen: Bool { type == .newEvent && composeUI.showConfirmScreen != true }
    var isConfirmNewEvent: Bool { type == .newEvent && composeUI.showConfirmScreen == true }
}


//Event Info Section -> Filling out details and confirm Invite Screen
extension RespondToInviteContainer {

    ///The two numbers this swap is tuned with. The lag holds the arriving body back until the leaving
    ///one is spent; the blur is what makes the frames where they do still overlap read as depth rather
    ///than a second printing of the same words. Floor for the lag is ~0.05 — under that the two fade
    ///windows meet again (`DropdownCustomMenuSpec.revealLaunchDelay` records the same 0.13).
    private static let swapLag: TimeInterval = 0.13
    private static let swapBlur: CGFloat = 6 //Not the house 8: a full-width body at 8 reads as a rack-focus

    ///Out on `.dismiss` — it gets out of the way — and in on `.transition` a beat later, into a box that
    ///has already stopped moving. Never `blurPop`'s default scale: a whole body shrinking reads as the
    ///card collapsing, not as a page leaving.
    private static func bodySwap(anchor: UnitPoint = .center) -> AnyTransition {
        .asymmetric(
            insertion: .blurPop(scale: 1, blur: swapBlur, anchor: anchor).animation(.transition.delay(swapLag)),
            removal:   .blurPop(scale: 1, blur: swapBlur, anchor: anchor).animation(.dismiss))
    }

    var eventInfoSection: some View {
        //Top-pinned: centred, the two bodies re-centre on each other, and the one leaving rides the
        //growth ~15pt down its own text while it fades — the smear. Pinned, only the bottom edge moves.
        ZStack(alignment: .top) {
            if type == .newEvent {
                inviteDetailsPager
                    .transition(Self.bodySwap())
            } else {
                respondToInvite
                    .transition(Self.bodySwap())
            }
        }
    }
    
    //Respond To Invite Screen
    var respondToInvite: some View {
        EventTypeTimePlace(
            invite: InviteSummary(event: vm.respondDraft.originalInvite.event),
            respondDraft: $vm.respondDraft,
            timePopupOpen: $composeUI.timePopupOpen, //One owner for both screens' time platter
            actionsBelow: true, //adjusts padding in this view if actions below
            shortSpacing: false,
            largeText: true,
            heroLanding: true, //The invite card's own time and place lines fly onto these rows
            openInfo: {composeUI.showInfoScreen = true}
        )
    }
    
    //The Compose and Confirm Invite Screens
    private var inviteDetailsPager: some View {
        VStack(spacing: 0) {
            TwoPageScrollView(
                showSecondScreen: $composeUI.showConfirmScreen,
                scrollProgress: .constant(0),
                reflowAnimation: vm.respondDraft.newEvent.hasChanges ? .transition : .dissolve, //An emptied draft is a clear
                screen1: { EditTypeTimePlace(ui: $composeUI, draft: $vm.respondDraft.newEvent) },
                screen2: { confirmEventView }
            )
        }
    }
    
    @ViewBuilder
    private var confirmEventView: some View {
        if let invite = InviteSummary(draft: vm.respondDraft.newEvent) {
            EventTypeTimePlace(invite: invite, actionsBelow: true, openInfo: { composeUI.showInfoScreen = true })
        }
    }
}


//Action Button Section
extension RespondToInviteContainer {
    
    var actionSection: some View {
        VStack {
//            if !isComposeInviteScreen { warningText }
            HStack(spacing: 18) {
                if type != .newEvent {
                    //Leaves the LAYOUT as it goes, so the CTA closes the gap behind it instead of
                    //holding a half-width slot for the whole curve and snapping wide on the last frame
                    declineButton.transition(Self.bodySwap(anchor: .leading))
                }
                ctaButton
            }
        }
        .padding(.bottom, 12)
        .padding(.horizontal, Spacing.margin) //Each page owns the gap above this button
    }
    
    //One flag for the whole action row: an open platter owns the finger, so the actions under it read as
    //unavailable. The CTA answers by swapping its fill to `.fillGray`; the outlined decline has no fill to
    //swap, so it dims instead. Shared so the two can never disagree about when they are stood down.
    var actionsDimmed: Bool { composeUI.typePopupOpen || composeUI.timePopupOpen }

    var ctaButton: some View {
        //Hoisted, so the button and the flight that lands on it can never disagree about its look
        let isActive = type != .newEvent || vm.respondDraft.newEvent.isComplete
        let dimmed = actionsDimmed
        let font: Font = type == .newTime ? .body(15, .bold) : .body(18, .bold)
        let lineLimit = type == .newTime ? 2 : 1 //The only two-line label
        let fill = WideActionButton.restingFill(isActive: isActive, isDimmed: dimmed)

        return WideActionButton(
            text: ctaText,
            isActive: isActive,
            isDimmed: dimmed,
            showShadow: false,
            font: font,
            height: type == .newEvent ? 46 : 48,
            lineLimit: lineLimit,
            glass: false, //The event zoom's capsule lands on this: flat, so it lands on identical pixels
            onTap: type == .originalInvite ? { ui.showAcceptAlert = true} : ctaAction
        )
        .eventZoomDragExclusion() //A press that slides off the button never scrubs the card
        .eventZoomButtonTarget(text: ctaText, fill: fill, font: font, lineLimit: lineLimit) //The invite card's envelope widens into this
    }
    
    var ctaText: String {
        switch type {
        case .originalInvite: "Accept"
        case .newTime: "Propose\nNew Times"
        case .newEvent: isComposeInviteScreen ? "Review" : "Invite \(vm.profile.name)"
        }
    }
    
    var ctaAction: () -> Void {
        switch type {
        case .originalInvite:{ respond(.accepted)}
        case .newTime: {respond(.newTime)}
        case .newEvent: isComposeInviteScreen ? { composeUI.showConfirmScreen = true} : {respond(.newInvite)}
        }
    }
    
    var declineButton: some View {
        Text("Decline")
            .font(.body(18, .bold))
            .opacity(actionsDimmed ? 0.2 : 1)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .capsuleStroke(lineWidth: 1, color: .borderStrong.opacity(actionsDimmed ? 0.4 : 1))
            .geometryGroup()
            .shrinkPress {respond(.decline)}
            .eventZoomDragExclusion()
    }
    
    var warningText: some View {
        Text("* If you accept & don't turn up you may be blocked")
            .font(.body(12.5, .regularItalic))
            .foregroundStyle(Color(red: 0.55, green: 0.55, blue: 0.55))
    }
    
    var selectedDayString: String {
        if let day = vm.respondDraft.originalInvite.selectedDay {
            return FormatEvent.shortDayAndTime(day, withHour: true, withMonth: true, withToday: false)
//            let hour = FormatEvent.hourTime(day)
//            return "\(dayWithMonth) at \(hour)"
        } else {
            return "a time"
        }
    }
    
}


/*
 //            if isComposeInviteScreen {
 //                OptionsMenu(
 //                    hasChanges: vm.respondDraft.newEvent.hasChanges,
 //                    onClear: {vm.respondDraft.newEvent = .init()},
 //                    onDecline: {respond(.decline)}
 //                )
 //            }

 */
