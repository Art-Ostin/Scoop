import SwiftUI
//Note: Geometry Reader needed to Keep the VStack from respecting the top safe Area

enum ProfileMode {
    case ownProfile(draft: UserProfile)
    case viewProfile
    case sendInvite(onSend: (EventFieldsDraft) -> Void, onDecline: () -> Void)
    case respondToInvite(respondVM: RespondViewModel, onResponse: (ProfileResponse) -> Void)
}

struct ProfileView: View {

    @Environment(\.dismiss) var dismiss
    @State var vm: ProfileViewModel

    // Present when the host container drives a card→pager image morph (Events);
    // nil hosts keep the slide presentation.
    @Environment(ProfileMorphState.self) var morph: ProfileMorphState?

    @State var ui = ProfileUIState()
    // Pending send action while the morph confirm alert is up — hoisted so the alert
    // is hosted full-screen above the frame-clamped morph card.
    @State var pendingInvite: (() -> Void)?
    // Respond-flow popup state, owned here so the morph card (the pager) and the
    // full-screen confirm alerts share one source of truth.
    @State var respondUI = RespondPopupUIState()

    let mode: ProfileMode
    let isMessageProfile: Bool
    let profileImages: [UIImage]
    let onDismiss: (() -> Void)?
    //When starting to dismiss trigger back button to expand (needed for chatContainer)
    let onDismissStart: (() -> Void)?

    var isUserProfile: Bool {
        if case .ownProfile = mode { true } else { false }
    }

    var displayProfile: UserProfile {
        if case .ownProfile(let draft) = mode { draft } else { vm.profile }
    }
    
    @State var showDetails = false

    init(
        vm: ProfileViewModel,
        isMessageProfile: Bool = false,
        profileImages: [UIImage],
        mode: ProfileMode,
        onDismiss: (() -> Void)? = nil,
        onDismissStart: (() -> Void)? = nil,
    ) {
        _vm = State(initialValue: vm)
        self.profileImages = profileImages
        self.mode = mode
        self.onDismiss = onDismiss
        self.onDismissStart = onDismissStart
        self.isMessageProfile = isMessageProfile
    }
    
    var body: some View {
        GeometryReader { geo in
            ZoomContainer {
                ZStack(alignment: .top) {
                    titleAndImage

                    detailsView
                }
                //1. Profile Background
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(profileBackground)
                //2. One gesture for the whole surface — paging, scrolling, moving the
                //card and dismissing are disambiguated in ProfileGestures.swift.
                .simultaneousGesture(profileDrag(geo: geo))
                .onAppear {
                    if isMessageProfile {
                        Task {
                            try? await Task.sleep(for: .seconds(0.1))
                            withAnimation(.easeInOut(duration: 0.15)) { showDetails = true }
                        }
                    }
                }

                //3.Specify coordinate space for measuring
                .coordinateSpace(name: "profileZStack")
            }
        }
        .onAppear { if isUserProfile { vm.viewProfileType = .view } }
        .overlay(alignment: .bottomTrailing) { inviteButton }
        .overlay(alignment: .bottomLeading) { declineButton }
        //Reverse-zoom dismissal: the drag shrinks the whole surface toward the
        //source card and a committed close converges onto it (ProfileMorph.swift).
        .profileZoomDismiss(ui: ui, enabled: !isUserProfile)
        // Send-invite AND respond-to-invite both morph out of the invite icon. Respond
        // mode hosts a multi-page pager that owns its own card chrome, so the morph
        // surface hands off (contentOwnsBackground) once expanded.
        .quickInviteMorph(
            iconId: sendInviteMorphId,
            morphInviteId: $ui.morphInviteId,
            hideCard: pendingInvite != nil,
            showsHideButton: !isRespondMode,
            style: (isRespondMode ? QuickInviteMorphStyle.respond : .send)
                .tinted(vm.viewProfileType == .invite ? .accent : .appGreen),
            // ProfileView already covers the tab bar, so present as an overlay to skip the
            // cover-presentation latency that makes the morph pop in collapsed before opening.
            presentsAsOverlay: true
        ) { _ in
            sendInviteMorphCard
        } overlay: {
            morphOverlay
        }
        .preference(key: ProfileDetailsOpenKey.self, value: ui.detailsOpen)
    }
}

extension ProfileView {
    
    //Rest position comes from layout (top padding); the drag moves everything with
    //transforms only, so no frame of a drag ever runs a layout pass.
    private var titleAndImage: some View {
        VStack(spacing: 24) {
            profileTitle()
                .modifier(DetailsFadeEffect(ui: ui, from: 1, to: 0, impactEnd: 0.75))

            ProfileImageView(ui: ui, vm: vm, importedImages: profileImages)
                .overlay(alignment: .topLeading) {
                    overlayTitle(onDismiss: dismissProfile)
                        .padding(.top, 12)
                        .modifier(DetailsFadeEffect(ui: ui, from: 0, to: 1, impactStart: 0.5))
                        .offset(x: isUserProfile ? 36 : 0)
                }
        }
        //Header height anchors the details card. A size is transform-independent, so
        //this fires on real layout changes only — never while dragging.
        .onGeometryChange(for: CGFloat.self) { geo in
            geo.size.height
        } action: { height in
            ui.headerHeight = height
        }
        .padding(.top, ui.headerTopPadding)
        .modifier(ProfileHeaderDragEffect(ui: ui))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var detailsView: some View {
        ProfileDetailsView(vm: vm, ui: ui, p: vm.profile, event: vm.event)
            .modifier(DetailsCardDragEffect(ui: ui))
            //Resting top edge in the gesture's space for the started-on-card test.
            //Geometry ignores the drag transform, so this is the layout position and
            //fires only on real layout changes — never while dragging.
            .onGeometryChange(for: CGFloat.self) { geo in
                geo.frame(in: .global).minY
            } action: { minY in
                ui.restingCardTopGlobal = minY
            }
            .padding(.top, ui.detailsRestingTop) //24 spacing between bottom of image, and start of details
            .opacity(showDetails || !isMessageProfile ? 1 : 0)
    }

    private var profileBackground: some View {
        //Plain rect: during the zoom dismissal every visible corner comes from
        //ZoomClipShape alone, so all four round identically. (The old top-24
        //rounding existed for the removed slide-down dismissal.)
        Rectangle()
            .fill(Color.appCanvas)
            .ignoresSafeArea()
            .customShadow(.card)
    }
}
