//
//  HistoryContainer.swift
//  Scoop
//
//  Created by Art Ostin on 20/08/2026.
//

import SwiftUI
import Glur
#if DEBUG
import MapKit //Harness stubs only — the shipping screen never touches it
#endif

struct HistoryContainer: View {
    
    @Environment(\.dismiss) private var dismiss
    @State var vm: HistoryViewModel
    
    @State private var selectedPage: Int? = 0
    
    @State private var ui = HistoryUIState()

    @State private var profileOpen = false

    @State private var pendingScroll = ScrollPosition()

    @State private var pendingChromeBack = false
    
    @State private var showEventInfo: EventProfile?
    
    private let fadeBand: CGFloat = 32

    private let expiredReveal: CGFloat = 400
    
    var body: some View {
        ZoomNavigationStack(isDetailPresented: $profileOpen) {
            VStack(spacing: 0) {
                headerBand
                
                scrollSection
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.canvasSunken.ignoresSafeArea())
            .task(id: vm.declines) { await loadDeclineImages() }
            .task(id: vm.sentInvites) { await loadInviteImages() }
            .overlay { dismissButtonLayer }
            .overlay { selectedPendingEvent } //Over the page's own chrome: its backdrop covers the screen
            .sheet(item: $showEventInfo) { eventProfile in
                Text(eventProfile.profile.name)
            }
        }
        .environment(ZoomPresentationHost?.none)
        .interactiveDismissDisabled(ui.selectedPending != nil || profileOpen)
        .ignoresSafeArea()
    }
}

//Logic to do with the header
extension HistoryContainer {
    //Sits hard against the pager, which clips the cards at the underline's baseline
    private var headerBand: some View {
        VStack(alignment: .leading, spacing: 24) {
            HistoryTitle(ui: ui)
            
            HistorySubHeading(ui: ui)
                .padding(.top, -12)
            
            SelectionSection(selectedPage: $selectedPage, ui: ui)
        }
        .padding(.top, 36)
        .padding(.horizontal, Spacing.gutter)
        .zIndex(1)
    }
    
    
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

    private var chromeVisible: Bool { ui.selectedPending == nil || pendingChromeBack }

    private var dismissButton: some View {
        ScoopButton(style: .glass, shape: Circle(), size: .xLarge, press: .grow) {
            dismiss()
        } label: {
            Image(systemName: "xmark") //"arrow.down.right.and.arrow.up.left"
                .foregroundStyle(.black)
                .font(.icon(18, .heavy))
        }
        .opacityPop(visible: chromeVisible)
        .allowsHitTesting(chromeVisible)
        //Its OWN value-keyed scope: selectPending writes bare on purpose (an animated mount
        //would flash the flight cover), so the pop cannot ride the call site's transaction
        .animation(.transition, value: chromeVisible)
    }
    
    private func loadDeclineImages() async {
        for decline in vm.declines where vm.profileImages[decline.id] == nil {
            await vm.loadProfileImages(decline.profile.profile)
        }
    }

    private func loadInviteImages() async {
        for invite in vm.sentInvites where vm.profileImages[invite.profile.id] == nil {
            await vm.loadProfileImages(invite.profile)
        }
    }
}

extension HistoryContainer {
    
    private var scrollSection: some View {
        HistoryPager(selectedPage: $selectedPage, progress: $ui.pagerProgress) {
            pendingInvitesView
                .containerRelativeFrame(.horizontal)
                .id(0)
            
            pastDeclineSection
                .containerRelativeFrame(.horizontal)
                .id(1)
        }
        .contentMargins(.top, -1, for: .scrollContent) //Fixes subtle spacingBug
    }
    
    private func page<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            content()
        }
        .contentMargins(.top, fadeBand, for: .scrollContent)
        .scrollIndicators(.hidden)
        .customScrollFade(height: fadeBand, color: .canvasWarm, curve: .even)
    }
    
    private var pastDeclineSection: some View {
        page {
            RecentDeclines(declines: vm.declines,
                           profileImages: vm.profileImages,
                           imageLoader: vm.imageLoader,
                           defaults: vm.defaults)
        }
    }
    
    private var pendingInvitesView: some View {
        page {
            PendingInvitesView(days: vm.invitedDays,
                               expiredInvites: vm.expiredInvites,
                               ui: ui,
                               onSelect: selectPending)
        }
        .scrollPosition($pendingScroll)
        .drawerNudge(isOpen: ui.showsExpired, by: expiredReveal, position: $pendingScroll)
    }
}

//The detail card a ledger lens opens
extension HistoryContainer {

    @ViewBuilder
    private var selectedPendingEvent: some View {
        if let invite = ui.selectedPending {
            SelectedPendingEvent(eventProfile: invite,
                                 images: vm.images(for: invite),
                                 sourceRect: ui.pendingSource,
                                 glassRing: ui.pendingGlassRing,
                                 openEventInfo: $showEventInfo,
                                 onClosing: pendingClosing,
                                 onChromeReturn: pendingChromeReturn,
                                 onClosed: pendingClosed)
        }
    }

    //Bare writes, no animation: the card mounts with its flight cover standing on the hidden
    //lens' exact pixels and choreographs its own arrival — an animated mount would flash
    private func selectPending(_ invite: EventProfile, sourceRect: CGRect) {
        ui.pendingSource = sourceRect
        ui.selectedPending = invite
        pendingChromeBack = false //A fresh card takes the corner back from the last close
    }

    //A committed close is flying home: the ledger's static ring hides (a bare write, behind
    //the still-full backdrop) so the flight's expanding glass owns the slot
    private func pendingClosing() {
        ui.lensReturning = true
    }

    //A beat further into that close: the chevron has popped away and the backdrop's frost has
    //lifted, so the corner is clear and History's own xmark comes back over the still-flying card
    private func pendingChromeReturn() {
        pendingChromeBack = true
    }

    //The close flight has landed on the lens — its overshoot settle IS the landing beat —
    //so the card unmounts and the lens returns in the same commit, identical pixels
    private func pendingClosed() {
        ui.selectedPending = nil
        ui.pendingSource = .zero
        ui.selectedLensID = nil //The photo is home: the lens takes its pixels back in the same commit
        ui.lensReturning = false
        pendingChromeBack = false //The xmark is already in; selectedPending going nil holds it there
    }
}

//Its own Title -> Fixes bug
private struct HistoryTitle: View {
    //Injected
    let ui: HistoryUIState

    private var showsDeclines: Bool { ui.pagerProgress > 0.5 }

    var body: some View {
        ZStack(alignment: .leading) {
            Text(showsDeclines ? "Declined Profiles" : "Pending Invites")
                .font(.title(32, .bold))
                .id(showsDeclines)
                .transition(.blurReplace)
        }
        .animation(.transition, value: showsDeclines)
    }
}

struct HistoryPager<Content: View>: View {
    //Injected
    @Binding var selectedPage: Int?
    var progress: Binding<Double> = .constant(0)
    @ViewBuilder let content: Content

    //Local view state
    @State private var pagedId: Int? = 0
    @State private var scrollDriven = false

    var body: some View {
        HorizontalScrollView(progress: progress) {
            content
        }
        .scrollPosition(id: $pagedId)
        .animation(scrollDriven ? nil : .move, value: pagedId)
        .onChange(of: selectedPage) { _, newPage in
            guard let newPage, newPage != pagedId else { return }
            pagedId = newPage
        }
        .onScrollPhaseChange { _, phase in
            scrollDriven = phase == .interacting || phase == .decelerating
            guard phase == .idle, pagedId != selectedPage else { return }
            selectedPage = pagedId
        }
    }
}


private struct HistorySubHeading: View {
    
    //Injected
    let ui: HistoryUIState

    private var showsDeclines: Bool { ui.pagerProgress > 0.5 }

    var body: some View {
        ZStack(alignment: .leading) {
            Text(showsDeclines ? recentDeclinesText : pendingInvitesText)
                .font(.body(14, .medium))
                .foregroundStyle(Color.textSecondary)
                .id(showsDeclines)
                .transition(.blurReplace)
        }
        .animation(.transition, value: showsDeclines)
    }
    
    
    private var pendingInvitesText: String {
        "Invites awaiting a reply, and the days you proposed"
    }
    
    private var recentDeclinesText: String {
        "You can still respond to them for 3 days after declining"
    }
}

#if DEBUG
//MARK: - Sim harness (-uiHarnessPendingFlight)
//The ledger + lens flight on stubbed invites, reachable without an account. Capture
//scaffolding for the flight work — delete once the flight is device-verified.
struct PendingFlightHarness: View {

    @State private var ui = HistoryUIState()
    private let stubs = PendingFlightStubs()

    var body: some View {
        ZStack {
            Color.canvasSunken.ignoresSafeArea()

            ScrollView {
                PendingInvitesView(days: stubs.days, expiredInvites: [], ui: ui, onSelect: select)
                    .padding(.top, Spacing.xxl)
            }
            .scrollIndicators(.hidden)
        }
        .overlay { card }
    }

    @ViewBuilder
    private var card: some View {
        if let invite = ui.selectedPending {
            SelectedPendingEvent(eventProfile: invite,
                                 images: stubs.images(for: invite),
                                 sourceRect: ui.pendingSource,
                                 glassRing: ui.pendingGlassRing, openEventInfo: .constant(nil),
                                 onClosing: { ui.lensReturning = true },
                                 onChromeReturn: { }, //The harness has no screen chrome to bring back
                                 onClosed: closed)
        }
    }

    //Mirrors HistoryContainer.selectPending / pendingClosed — the wiring under test
    private func select(_ invite: EventProfile, sourceRect: CGRect) {
        ui.pendingSource = sourceRect
        ui.selectedPending = invite
    }

    private func closed() {
        ui.selectedPending = nil
        ui.pendingSource = .zero
        ui.selectedLensID = nil
        ui.lensReturning = false
    }
}

//Three people across mixed days: primaries, echoes, and an echo-only middle-tier day
@MainActor
struct PendingFlightStubs {

    let days: [InviteDay]
    private let invites: [EventProfile]
    private let imageSets: [String: [UIImage]]

    init() {
        let mia = UserProfile(harnessID: "p-mia", name: "Mia")
        let leo = UserProfile(harnessID: "p-leo", name: "Leo")
        let zoe = UserProfile(harnessID: "p-zoe", name: "Zoe")

        let miaImages = [Self.photo(.systemPink, "M"), Self.photo(.systemIndigo, "M")]
        let leoImages = [Self.photo(.systemTeal, "L"), Self.photo(.systemBrown, "L")]
        let zoeImages = [Self.photo(.systemOrange, "Z")]

        let all = [
            Self.invite(id: "evt-mia", profile: mia, dayOffsets: [0, 3], hour: 19, image: miaImages[0], message: "Been meaning to try this place"),
            Self.invite(id: "evt-leo", profile: leo, dayOffsets: [1, 3, 6], hour: 20, image: leoImages[0], message: nil),
            Self.invite(id: "evt-zoe", profile: zoe, dayOffsets: [1], hour: 18, image: zoeImages[0], message: "Long time!"),
        ]
        invites = all
        imageSets = ["p-mia": miaImages, "p-leo": leoImages, "p-zoe": zoeImages]

        //Grouped as HistoryViewModel.invitedDays groups them
        let cal = Calendar.current
        var byDay: [Date: [EventProfile]] = [:]
        for invite in all {
            for time in invite.event.proposedTimes.availableTimes() {
                byDay[cal.startOfDay(for: time.date), default: []].append(invite)
            }
        }
        days = byDay.map { InviteDay(day: $0.key, invites: $0.value) }.sorted { $0.day < $1.day }
    }

    func images(for invite: EventProfile) -> [UIImage] {
        imageSets[invite.profile.id] ?? invite.image.map { [$0] } ?? []
    }

    private static func invite(id: String, profile: UserProfile, dayOffsets: [Int], hour: Int, image: UIImage, message: String?) -> EventProfile {
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        let dates = dayOffsets
            .compactMap { cal.date(byAdding: .day, value: $0, to: start) }
            .compactMap { cal.date(bySettingHour: hour, minute: 30, second: 0, of: $0) }

        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 45.5088, longitude: -73.5878))
        let item = MKMapItem(placemark: placemark)
        item.name = "Café Olimpico"

        let event = UserEvent(harnessID: id,
                              otherProfile: profile,
                              type: .drink,
                              proposedTimes: ProposedTimes(items: dates.map { .init(date: $0) }),
                              location: EventLocation(mapItem: item),
                              message: message)
        return EventProfile(event: event, profile: profile, image: image)
    }

    private static func photo(_ color: UIColor, _ label: String) -> UIImage {
        let size = CGSize(width: 600, height: 750)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.white.withAlphaComponent(0.35).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 150, y: 120, width: 300, height: 300))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 160, weight: .bold),
                .foregroundColor: UIColor.white,
            ]
            let text = NSAttributedString(string: label, attributes: attrs)
            let bounds = text.boundingRect(with: CGRect(origin: .zero, size: size).size, options: [], context: nil)
            text.draw(at: CGPoint(x: (size.width - bounds.width) / 2, y: 480))
        }
    }
}

//Harness-only constructors: every stored property set directly, so no Firestore decoder is
//involved. DEBUG scaffolding — the app never calls these.
extension UserProfile {
    init(harnessID: String, name: String) {
        id = harnessID
        email = "\(harnessID)@harness.local"
        self.name = name
        sex = ""; year = ""; height = ""; lookingFor = ""; degree = ""; hometown = ""
        nationality = []; interests = []
        prompt1 = PromptResponse(prompt: "", response: "")
        prompt2 = PromptResponse(prompt: "", response: "")
        drinking = ""; smoking = ""; marijuana = ""; drugs = ""
        imagePath = []; imagePathURL = []
        attractedTo = ""
        createdAt = nil
    }
}
#endif
