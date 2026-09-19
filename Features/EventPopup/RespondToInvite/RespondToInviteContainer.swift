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
    let respond: (ProfileResponse, SendInviteFlightSource?) -> () //A sent time or invite hands over the page on screen — the cover's hero lifts off it

    var type: ResponseType { vm.respondDraft.respondType }
    
    @FocusState var isFocused: Bool
    @Environment(EventZoomChoreo.self) private var flight: EventZoomChoreo? //The zoom the card stands in: its ride leaves in the same commit as the note's

    //Local view state
    @State private var rowsHeight: CGFloat = 0 //The type/time/place block as laid out — what the focused note scrolls behind the photo
    @State private var noteOpen = false //`isFocused` as everything that MOVES reads it — never the raw focus (see `rideNote`)
    @State private var noteRideGate = KeyboardSettleGate(smoothTicks: 0) //A focus's ride leaves on the first frame the keyboard's arrival lets through
    @State private var showsNoteTitle = false //`isFocused` as the title and the placeholder's words read it — never the raw focus (see `retitle`)
    @State private var noteTitleGate = KeyboardSettleGate() //A focus's retitle waits here until the keyboard's arrival stops stalling frames

    //Card content only: `.eventZoom` draws the backdrop, the white surface and the chevron around it
    var body: some View {
        VStack(spacing: 0) {
            imagePager
            VStack(spacing: 0) {
                Group {
                    eventInfoSection
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                            withAnimation(rowsHeight > 0 ? .transition : nil) { rowsHeight = height } //A rewrap mid-focus rides the card's resize clock; the first reading lands bare
                        }
                        .noteRevealRows(isOpen: noteOpen, isFocused: isFocused, room: noteRevealRoom)
                    messageSection
                        .environment(\.noteRevealRoom, noteRevealRoom)
                }
            }
            .clipped() //The photo's foot: what the rows leave under, and the thread slides under as it rises

            actionSection
                .padding(.top, 4)
        }
        .contentShape(Rectangle())
        .onTapGesture { closeNote() }
    
        .animation(.transition, value: [
            composeUI.delayedTimePopupOpen,
            composeUI.delayedTypePopupOpen,
            isFocused, composeUI.showConfirmScreen]
        )
        
        .eventZoomKeyboardFocus(isFocused, riding: noteOpen, extraLift: noteRevealLift) { closeNote() }
        .onChange(of: isFocused) { _, focused in
            rideNote(focused)
            retitle(focused)
        }
        .onDisappear {
            noteRideGate.cancel()
            noteTitleGate.cancel()
        }
        .eventZoomChevronHidden(isConfirmNewEvent)
        .eventZoomDragLocked(composeUI.typePopupOpen || composeUI.timePopupOpen || ui.showAcceptAlert)
        
        .sheet(isPresented: $composeUI.showInfoScreen) { Text("How it works")}
        .sheet(isPresented: $composeUI.showMessageScreen) { addMessageView }
        .fullScreenCover(isPresented: $composeUI.showMapView) {
            MapView(defaults: vm.defaults, eventLocation: $vm.respondDraft.newEvent.place)
        }
        .eventZoomAlert(
            isPresented: $ui.showAcceptAlert,
            title: confirmAlertTitle,
            emoji: "🧟",
            message: confirmAlertText,
            cancelTitle: "Back",
            okTitle: "Confirm",
            offset: 36,
            onOK: { ctaAction() }, //
            onCancel:  isComposeInviteScreen ?  { composeUI.showConfirmScreen = true } : { ui.showAcceptAlert = false}
        )
        .sheet(isPresented: $ui.showHistorySheet) {inviteHistoryContainer}
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
                        bandGround: composeUI.timeBand,
                        visiblePhoto: $composeUI.visiblePhoto)
        //The pager's frame IS the photo's — its root is the aspect box the carousel overlays
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { composeUI.photoFrame = $0 }
        .overlay(alignment: .topLeading) {
            EventBackButton(showConfirmScreen: $composeUI.showConfirmScreen)
                .eventZoomBandChrome(visible: isConfirmNewEvent, corner: .topLeading) { inertBackButton }
        }
        .overlay(alignment: .topTrailing) {
            cornerRow(inert: false)
                .blurPop(visible: cornerVisible, scale: 1)
                .eventZoomBandChrome(corner: .topTrailing) { if cornerVisible { cornerRow(inert: true) } }
        }
    }
        
    var titleText: String {
        if showsNoteTitle {
            return hasPreviousMessages ? "Message Thread" : "Add a Note"
        } else {
            switch type {
            case .originalInvite: return "\(vm.profile.name)'s Invite"
            case .newTime: return "Invite \(vm.profile.name)"
            case .newEvent: return composeUI.showConfirmScreen == true ? "Confirm Invite" : "Invite \(vm.profile.name)"
            }
        }
    }

    private func rideNote(_ focused: Bool) {
        noteRideGate.cancel()
        guard focused else {
            closeRide()
            return
        }
        noteRideGate.arm {
            guard isFocused, !noteOpen else { return } //Live, not the captured `focused`: a Done inside the wait wins
            flight?.setKeyboardRide(true) //The shell first: its transaction and the body's below flush in one commit, the shell's clock already open
            withAnimation(.keyboard) { noteOpen = true }
        }
    }

    //A written note's bubble is a pose of the note's own surface, flipped by this very write (the bar's `restsAsBubble`):
    //field ⇄ bubble is part of the ride, in its transaction, on its spring. Nothing waits for the ride to be home
    private func closeRide() {
        guard noteOpen else { return } //A focus that never rode: nothing left its place
        flight?.setKeyboardRide(false) //The shell first, as on the way up
        withAnimation(.keyboard) { noteOpen = false }
    }

    private func closeNote() {
        guard isFocused else { return }
        noteRideGate.cancel()
        closeRide()
        isFocused = false
    }

    private func retitle(_ focused: Bool) {
        noteTitleGate.cancel()
        guard focused else {
            if showsNoteTitle { withAnimation(.transition) { showsNoteTitle = false } }
            return
        }
        noteTitleGate.arm {
            guard isFocused, !showsNoteTitle else { return } //Live, not the captured `focused`: a Done inside the wait wins
            withAnimation(.transition) { showsNoteTitle = true }
        }
    }

    //What the note answers, oldest first: the retired rounds, then the live proposal. The message being
    //answered is the invite's own field until a counter retires it into the log, so it is not in
    //`pastProposals` yet — on a first invite that log is empty and this is the only message there is
    var messageThread: [PastEventProposal] {
        let event = vm.respondDraft.originalInvite.event
        return (event.pastProposals ?? []) + [PastEventProposal(retiring: event)]
    }

    var hasPreviousMessages: Bool {
        RespondNoteRevealSpec.messageCount(in: messageThread) > 0
    }
    
    
    var isPastInvites: Bool {
        vm.respondDraft.originalInvite.event.pastProposals?.isEmpty == false
    }
    
    @ViewBuilder
    private func cornerRow(inert: Bool) -> some View {
        
        if isPastInvites && type != .newEvent {
            OptionsMenu(
                inert: inert,
                showPastInvites: { ui.showHistorySheet = true },
                showNewInvite: { switchEventType() }
            )
            .eventZoomCornerTarget(inset: OptionsMenu.discInset, visible: cornerVisible) { OptionsMenu.disc }
        } else  {
            HStack(spacing: Spacing.xs) {
                NewEventToggleButton(inert: inert, isNewEvent: type == .newEvent) {
                    switchEventType()
                }
                
                if isPastInvites {
                    InviteHistoryIconButton(inert: inert, showHistorySheet: $ui.showHistorySheet)
                        .eventZoomCornerTarget(visible: cornerVisible) { InviteHistoryIconButton.disc }
                }
            }
            .padding(.trailing, isPastInvites ? 18 : 24)
        }
    }
    
    
    private func switchEventType() {
        withAnimation(.transition) {
            composeUI.showConfirmScreen = false
            if type == .newEvent {
                if vm.respondDraft.originalInvite.event.proposedTimes.availableTimes().isEmpty {
                    vm.respondDraft.respondType = .newTime
                } else {
                    vm.respondDraft.respondType = .originalInvite
                }
            } else {
                vm.respondDraft.respondType = .newEvent
            }
        }
    }

    var inertBackButton: some View {
        EventBackButton(showConfirmScreen: $composeUI.showConfirmScreen, inert: true)
    }

    //The corner's own hide: a popup's platter or a focused note owns the card
    var cornerVisible: Bool { !(composeUI.delayedTimePopupOpen || isFocused) }
    
    var isComposeInviteScreen: Bool { type == .newEvent && composeUI.showConfirmScreen != true }
    var isConfirmNewEvent: Bool { type == .newEvent && composeUI.showConfirmScreen == true }

    //How far the focused note's scroll grows up over the rows (RespondNoteReveal)
    private var noteRevealRoom: CGFloat { RespondNoteRevealSpec.room(over: rowsHeight) }

    //How far past the shell's pin the focused card rides: only once the thread holds more than one message (RespondNoteReveal)
    private var noteRevealLift: CGFloat { RespondNoteRevealSpec.lift(over: messageThread) }
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
            //One view, written or not: a written note rests as a bubble, and the bubble is a pose of the bar's own
            //surface (its `noteSurface`), so field ⇄ bubble morphs inside the note's ride instead of swapping after it
            RespondToMessageBar(
                text: $vm.respondDraft.newTime.respondMessage,
                thread: messageThread,
                hasPreviousMessages: hasPreviousMessages,
                userId: vm.userId,
                otherUserId: vm.profile.id,
                isFocused: $isFocused,
                isOpen: noteOpen,
                namesNote: showsNoteTitle,
                onDone: closeNote
            )
            .transition(Self.bodySwap())
        }
    }

    private var inviteHasMessage: Bool {
        vm.respondDraft.originalInvite.event.message?.isEmpty == false
    }
    
    private var pastResponseButton: some View {
        InviteHistoryIconButton(showHistorySheet: $ui.showHistorySheet)
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
    
    var actionsDimmed: Bool { composeUI.delayedTypePopupOpen || composeUI.delayedTimePopupOpen || ui.showAcceptAlert }
    
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
            onTap: isComposeInviteScreen ? {showConfirmScreen()} : {ui.showAcceptAlert = true}
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
        case .originalInvite:{ respond(.accepted, nil)}
        case .newTime: {respond(.newTime, sendFlightSource)}
        case .newEvent: { respond(.newInvite, sendFlightSource) }
        }
    }
    
    private func showConfirmScreen () {
        withAnimation(.transition) { composeUI.showConfirmScreen = true }
    }

    //Read at the tap, never in body: the card is at rest whenever the CTA can be pressed
    private var sendFlightSource: SendInviteFlightSource? {
        guard let image = composeUI.visiblePhoto, composeUI.photoFrame.width > 1 else { return nil }
        return SendInviteFlightSource(image: image, frame: composeUI.photoFrame, cornerRadius: CornerRadius.image)
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
            .shrinkPress {respond(.decline, nil)}
            .eventZoomDragExclusion()
    }
    
    var selectedDayString: String {
        if let day = vm.respondDraft.originalInvite.selectedDay {
            let time = FormatEvent.shortDayAndTime(day, withHour: false, withMonth: true, withToday: false)
            let hour = FormatEvent.hourTime(day)
            return "\(time) at \(hour)"
        } else {
            return "a time"
        }
    }
}

//Extra Views
extension RespondToInviteContainer {
    
    private var addMessageView: some View {
        AddMessageView(message: $vm.respondDraft.newEvent.message,
                       isRespondMessage: false,
                       eventType: $vm.respondDraft.newEvent.type)
    }
    
    @ViewBuilder
    private var inviteHistoryContainer: some View {
        if let profileImage = images.first {
            InviteHistoryContainer(
                event: vm.respondDraft.originalInvite.event,
                profileImage: profileImage,
                userImage: vm.userImage
            )
        }
    }
    
    
    private var confirmAlertTitle: String {
        switch type {
        case .originalInvite: return "Meet \(vm.profile.name)"
            
        default: return "Invite \(vm.profile.name)"
        }
    }
    
    private var confirmAlertText: String {
        switch type {
        case .originalInvite:
            "You're committing to meet on \(selectedDayString). Not showing will get your account blocked."
        default:
            "You're committing to an in person event. If \(vm.profile.name) accepts & you don't show your account may be blocked."
        }
    }
}


/*    var hasMessage: Bool {
 vm.respondDraft.originalInvite.event.message?.isEmpty == false
}

var isPastInvites: Bool {
 vm.respondDraft.originalInvite.event.pastProposals?.isEmpty == false
}

var showPastInvitesOnImage: Bool {
 if isPastInvites && !(type == .originalInvite && !hasMessage) && !isFocused { return true }
 else { return false}
}

var showPastInvitesOnPage: Bool {
 if isPastInvites && (type == .originalInvite && !hasMessage) { return true }
 else { return false }
}
 if vm.respondDraft.originalInvite.event.pastProposals?.isEmpty == false {
     pastResponseButton
//                    .blurPop(visible: showPastInvitesOnPage)
 }

*/
