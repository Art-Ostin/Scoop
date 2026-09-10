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
    
    @FocusState var isFocused: Bool

    //Local view state
    @State private var rowsHeight: CGFloat = 0 //The type/time/place block as laid out — what the focused note scrolls behind the photo
    
    //Card content only: `.eventZoom` draws the backdrop, the white surface and the chevron around it
    var body: some View {
        VStack(spacing: 0) {
            imagePager
            VStack(spacing: 0) {
                Group {
                    eventInfoSection
                        .getHeight($rowsHeight)
                        .allowsHitTesting(!isFocused) //Under the photo's edge while lifted: a clip hides, it does not fence
                    messageSection
                }
                .offset(y: isFocused ? -focusLift : 0)
            }
            .clipped()
            .animation(.move, value: isFocused) //A position settle, on the clock the shell raises the whole card on

            actionSection
                .padding(.top, 4)
        }
        .contentShape(Rectangle()) //The card's empty white too: a tap anywhere on it hands the keyboard back
        .onTapGesture { if isFocused { isFocused = false } } //Buttons and the bar's own tap win over this, as children do
        .animation(.transition, value: isFocused)
        .eventZoomKeyboardFocus(isFocused) { isFocused = false } //The shell lifts the card to the top, routes the backdrop tap here, and holds the drag
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
            onOK: { ctaAction() }, //
            onCancel: {ui.showAcceptAlert = false}
        )
        .animation(.transition, value: [composeUI.delayedTimePopupOpen, composeUI.delayedTypePopupOpen])
        .sheet(isPresented: $ui.showHistorySheet) {
            if let profileImage = images.first {
                InviteHistoryContainer(
                    event: vm.respondDraft.originalInvite.event,
                    profileImage: profileImage,
                    userImage: vm.userImage
                )
            }
        }
    }
}

//ImagePager logic
extension RespondToInviteContainer {
    
    
    var imagePager: some View {
        EventImagePager(images: images,
                        title: titleText,
                        showsPageDots: !isConfirmNewEvent,
                        titleVisible: !composeUI.delayedTimePopupOpen,
                        bandFilled: composeUI.timePopupOpen && composeUI.delayedTimePopupOpen,
                        bandGround: composeUI.timeBand)
        .overlay(alignment: .topLeading) {
            backButton.eventZoomBandChrome(visible: isConfirmNewEvent, corner: .topLeading) { inertBackButton }
        }
        .overlay(alignment: .topTrailing) {
            topRow
                .blurPop(visible: !(composeUI.delayedTimePopupOpen || isFocused), scale: 1)
                .eventZoomBandChrome(corner: .topTrailing) { inertTopRow }
        }
    }
    
    var titleText: String {
        if isFocused {
            return "Add a Note"
        } else {
            switch type {
            case .originalInvite: return "\(vm.profile.name)'s Invite"
            case .newTime: return "Invite \(vm.profile.name)"
            case .newEvent: return composeUI.showConfirmScreen == true ? "Confirm Invite" : "Invite \(vm.profile.name)"
            }
        }
    }
    
    var backButton: some View {
        EventBackButton(showConfirmScreen: $composeUI.showConfirmScreen)
    }

    var topRow: some View {
        HStack(spacing: 6) {
            NewEventToggleButton(
                responseType: $vm.respondDraft.respondType,
                showConfirmScreen: $composeUI.showConfirmScreen,
                noAvailableDays: vm.respondDraft.originalInvite.event.proposedTimes.availableTimes().isEmpty
            )
        }
        .animation(.transition, value: isComposeInviteScreen)
    }

    var inertBackButton: some View {
        EventBackButton(showConfirmScreen: $composeUI.showConfirmScreen, inert: true)
    }

    var inertTopRow: some View {
        HStack(spacing: 6) {
            NewEventToggleButton(
                responseType: $vm.respondDraft.respondType,
                showConfirmScreen: $composeUI.showConfirmScreen,
                inert: true,
                noAvailableDays: vm.respondDraft.originalInvite.event.proposedTimes.availableTimes().isEmpty
            )
        }
    }
    
    var isComposeInviteScreen: Bool { type == .newEvent && composeUI.showConfirmScreen != true }
    var isConfirmNewEvent: Bool { type == .newEvent && composeUI.showConfirmScreen == true }

    //How far the rows and the bar scroll: the rows' whole block plus the bar's own inset above its glass,
    //less the gap the glass keeps below the photo. Measured, not guessed — the type row grows with a note
    var focusLift: CGFloat {
        max(rowsHeight + RespondToMessageBar.fieldTopInset - Spacing.sm, 0)
    }
}


//Event Info Section -> Filling out details and confirm Invite Screen
extension RespondToInviteContainer {

    private static let swapLag: TimeInterval = 0.13
    private static let swapBlur: CGFloat = 6 //Not the house 8: a full-width body at 8 reads as a rack-focus

    private static func bodySwap(anchor: UnitPoint = .center) -> AnyTransition {
        .asymmetric(
            insertion: .blurPop(scale: 1, blur: swapBlur, anchor: anchor).animation(.transition.delay(swapLag)),
            removal:   .blurPop(scale: 1, blur: swapBlur, anchor: anchor).animation(.dismiss))
    }

    var eventInfoSection: some View {
        ZStack(alignment: .top) {
            if type == .newEvent {
                inviteDetailsPager
                    .transition(Self.bodySwap())
            } else {
                respondToInvite
                    .transition(Self.bodySwap())
            }
        }
        .overlay(alignment: .topTrailing) {
            if vm.respondDraft.originalInvite.event.pastProposals?.isEmpty == false {
                pastResponseButton
            }
            
        }
    }
    
    //Respond To Invite Screen
    var respondToInvite: some View {
        EventTypeTimePlace(
            invite: InviteSummary(event: vm.respondDraft.originalInvite.event),
            respondDraft: popupDraft, //Everything the time popup writes comes back through here
            timePopupOpen: $composeUI.timePopupOpen, //One owner for both screens' time platter
            timePopupOpenDelayed: composeUI.delayedTimePopupOpen, //…and the chrome's own 120/40ms clock
            actionsBelow: true, //adjusts padding in this view if actions below
            shortSpacing: false,
            largeText: true,
            heroLanding: true, //The invite card's own time and place lines fly onto these rows
            bandGround: composeUI.timeBand, //The time platter's band reports through this row
            openInfo: {composeUI.showInfoScreen = true}
        )
    }

    private var popupDraft: Binding<RespondDraft> {
        Binding(
            get: { vm.respondDraft },
            set: { draft in
                let current = vm.respondDraft.respondType
                guard draft.respondType != current else {
                    vm.respondDraft = draft
                    return
                }
                var edit = draft
                edit.respondType = current
                vm.respondDraft = edit //The edit itself (a day, a wheel tick) keeps the popup's own timing
                withAnimation(.transition) { vm.respondDraft.respondType = draft.respondType }
            }
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

//Message Section
extension RespondToInviteContainer {
    
    @ViewBuilder
    var messageSection: some View {
        if type == .newTime {
            RespondToMessageBar(text: $vm.respondDraft.newTime.respondMessage, isFocused: $isFocused)
                .transition(Self.bodySwap())
        }
    }
    
    private var pastResponseButton: some View {
        ScoopButton(style: .clearGlass, shape: Circle(), size: .small, press: .grow) {
            ui.showHistorySheet = true
        } label: {
            Image(.historyIcon)
                .resizable()
                .frame(width: 15, height: 15)
        }
        .padding(.vertical)
        .padding(.horizontal, 24)
    }
}

//Action Button Section
extension RespondToInviteContainer {
    
    var actionSection: some View {
        VStack {
            HStack(spacing: 18) {
                if type != .newEvent {
                    declineButton.transition(Self.bodySwap(anchor: .leading))
                }
                ctaButton
            }
        }
        .padding(.bottom, 12)
        .padding(.horizontal, Spacing.margin) //Each page owns the gap above this button
    }
    
    var actionsDimmed: Bool { composeUI.delayedTypePopupOpen || composeUI.delayedTimePopupOpen }
    
    var ctaButton: some View {
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
            glass: false,
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
    
    var isActive: Bool {
        if isFocused  {
            return false
        } else {
            switch type {
            case .originalInvite: return vm.respondDraft.originalInvite.selectedDay != nil
            case .newTime:    return    !vm.respondDraft.newTime.proposedTimes.dates.isEmpty
            case .newEvent:  return     vm.respondDraft.newEvent.isComplete
            }
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
    
    var selectedDayString: String {
        if let day = vm.respondDraft.originalInvite.selectedDay {
            return FormatEvent.shortDayAndTime(day, withHour: true, withMonth: true, withToday: false)
        } else {
            return "a time"
        }
    }
}
