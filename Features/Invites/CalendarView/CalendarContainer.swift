//
//  CalendarContainer.swift
//  Scoop
//
//  Created by Art Ostin on 14/09/2026.
//

import SwiftUI

struct CalendarContainer: View {
    
    @State var profileOpen: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    @State private var eventZoomHost = EventZoomHost()
    
    let vm: InvitesViewModel
    let onRespond: (EventProfile, ProfileResponse) -> Void //The Invites tab's own response flow
    let onViewEvent: (EventProfile, EventZoomDeparture, InviteSummary) -> Void //The flight into Events: it closes this cover itself, from above it
    
    private static let title = "Calendar View"

    var body: some View {
        ZoomNavigationStack(isDetailPresented: $profileOpen) {
            titledScroll
                .overlay { dismissButtonLayer }
                .eventZoomHost(eventZoomHost)
        }
        .interactiveDismissDisabled(eventZoomHost.isPresenting || profileOpen)
        .ignoresSafeArea()
    }
}



extension CalendarContainer {
        
    //iOS 26 hands the title to the bar: it takes the large title's slot, centred, and collapses into the
    //inline title on scroll. iOS 18 has no such slot, so it keeps no bar and the title scrolls away with the content.
    @ViewBuilder
    private var titledScroll: some View {
        if #available(iOS 26.0, *) {
            NavigationStack {
                scroll(titleInContent: false)
                    .navigationTitle(Self.title) //The small centred title the big one collapses into
                    .toolbar {
                        ToolbarItem(placement: .largeTitle) { titleText } //Replaces the stock leading large title
                    }
                    .scoopNavigationBarFonts(title: Self.title)
            }
        } else {
            scroll(titleInContent: true)
        }
    }

    private func scroll(titleInContent: Bool) -> some View {
        ScrollView {
            VStack(spacing: 0) { //Each block below owns its own leading gap — no implicit ~8pt seams
                heading(titleInContent: titleInContent)
                    .frame(maxWidth: .infinity, alignment: .center)

                calendarEventsView
                    //One step below titleGap: the day grid carries its own air above the first label
                    .padding(.top, Spacing.xl)

                if !vm.expiredInvites.isEmpty {
                    expiredEvents //No divider or title when nothing has expired
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing.clearance + Spacing.xl)
            .padding(.horizontal, Spacing.margin)
        }
        .bottomScrollFade() //Directly on the scroll: the last rows dissolve rather than slide under the close button
        .scrollIndicators(.hidden)
        .background(Color.appCanvas.ignoresSafeArea())
        .task(id: [vm.invites, vm.acceptedEvents]) { await loadInviteImages() }
    }

    @ViewBuilder
    private func heading(titleInContent: Bool) -> some View {
        if titleInContent {
            VStack(spacing: Spacing.sm) {
                titleText
                subtitle
            }
            .padding(.top, Spacing.xxl)
        } else {
            subtitle
        }
    }

    private var titleText: some View {
        Text(Self.title)
            .font(.title(32, .bold))
    }

    private var subtitle: some View {
        Text("See the days you've been invited to meet. Remember one invite can propose up to 3 different days.")
            .customSubtitle()
    }
    
    //The response cover draws at the app root, under this cover, so the calendar closes before the Invites tab responds
    private func respond(_ invite: EventProfile, _ response: ProfileResponse) {
        dismiss()
        onRespond(invite, response)
    }
    
    //Skips profiles already in the cache, so photos the invite cards loaded aren't fetched again.
    //Fetched in parallel and one task per person, so the faces land together rather than left to
    //right, and two invites from the same person never fetch the same photos twice.
    private func loadInviteImages() async {
        var seen = Set<UserProfile.ID>()
        let profiles = (vm.invites + vm.acceptedEvents).map(\.profile).filter { seen.insert($0.id).inserted }

        await withTaskGroup(of: Void.self) { group in
            for profile in profiles {
                group.addTask { await vm.ensureImagesLoaded(for: profile) }
            }
        }
    }
}

//Calendar Title view
extension CalendarContainer {
    
    @ViewBuilder
    private var calendarEventsView: some View {
        if vm.invitedDays.isEmpty && vm.acceptedEvents.isEmpty {
            emptyNote //Ten blank rows say the same thing at ten times the length
        } else {
            CalendarPendingEvents(invites: vm.invitedDays,
                                  acceptedEvents: vm.acceptedEvents,
                                  onOpen: { invite, day in vm.respondVM(for: invite).select(day: day) },
                                  card: inviteCard,
                                  meetingCard: meetingCard)
        }
    }

    //The Invites tab shows its calendar button whether or not anything is still pending
    private var emptyNote: some View {
        Text("No one has proposed a day yet.")
            .customSubtitle()
    }

    //Pending rows and expired avatars open the same respond card
    private func inviteCard(_ invite: EventProfile) -> AnyView {
        AnyView(RespondToInviteContainer(vm: vm.respondVM(for: invite),
                                         images: vm.images(for: invite),
                                         respond: { respond(invite, $0) }))
    }

    //View Event goes on here, not inside ViewInvite: Meet's pending ledger shows that view too
    private func meetingCard(_ meeting: EventProfile) -> AnyView {
        guard let time = meeting.event.acceptedTime else { return AnyView(EmptyView()) }
        let summary = InviteSummary(accepted: meeting.event, at: time)
        return AnyView(ViewInvite(inviteSummary: summary,
                                  images: vm.images(for: meeting),
                                  name: meeting.profile.name,
                                  title: "Meeting \(meeting.profile.name)")
            .eventZoomLeadingAction("View Event") { onViewEvent(meeting, $0, summary) })
    }

    
    private var expiredDivider: some View {
        Capsule()
            .fill(Color.fillGray)
            .frame(maxWidth: .infinity, maxHeight: 1)
            .padding(.horizontal, 72) //Geometry: sets the divider's length, not a rhythm gap
    }

    
    private var expiredEvents: some View {
        VStack(spacing: Spacing.xl) {
            //A full rule, a step darker than the rows' own hairlines: this is a section break, not a row seam
            expiredDivider
            expiredEventsTitle
            CalendarExpiredEvents(expiredInvites: vm.expiredInvites, card: inviteCard)
        }
        .padding(.top, Spacing.xl)
    }
    
    private var expiredEventsTitle: some View {
        VStack(spacing: Spacing.sm) {
            Text("Expired Events")
                .font(.body(18, .italic))
                .foregroundStyle(Color.textPrimary)

            Text("Events where the proposed times have expired. Propose a new time to meet.")
                .customSubtitle(lineSpacing: Spacing.xxs)
                .padding(.horizontal, Spacing.margin)
        }
    }
}



//Dismiss Button logic
extension CalendarContainer {
        
    private var dismissButtonLayer: some View {
        GeometryReader { proxy in
            dismissButton
                .padding(.bottom, Spacing.xxl
                    + max(0, proxy.size.height + proxy.safeAreaInsets.top
                        + proxy.safeAreaInsets.bottom - UIScreen.main.bounds.height)) //Geometry: the library's canvas overgrowth, read from inside the safe-area frame
                .padding(.horizontal, Spacing.margin)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }
    
    private var dismissButton: some View {
        ScoopButton(style: .glass, shape: Circle(), size: .xLarge, press: .grow) {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .foregroundStyle(.black)
                .font(.icon(18, .heavy))
        }
        .opacityPop(visible: chromeVisible)
        .allowsHitTesting(chromeVisible)
        .animation(.transition, value: chromeVisible)
    }

    private var chromeVisible: Bool { !eventZoomHost.chromeHidden }
}

//iOS 26 dissolves content into the canvas at a scroll edge; before it, a painted fade does the
//same job. `scrollFadeIfAvailable` is the chat's, and pins its pre-26 fallback to the top edge.
private extension View {

    @ViewBuilder
    func bottomScrollFade() -> some View {
        if #available(iOS 26.0, *) {
            scrollEdgeEffectStyle(.soft, for: .bottom)
        } else {
            customScrollFade(height: Spacing.clearance, showFade: true, edge: .bottom)
        }
    }
}
