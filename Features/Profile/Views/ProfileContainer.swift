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

    @State var ui = ProfileUIState()
    @State private var imageBottomSettleTask: Task<Void, Never>?
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
                    titleAndImage(geo: geo)
                        .simultaneousGesture(profileDrag(geo: geo))
                    
                    detailsView
                }
                //1. Profile Background
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(profileBackground)
                .onAppear {
                    if isMessageProfile {
                        Task {
                            try? await Task.sleep(for: .seconds(0.1))
                            withAnimation(.easeInOut(duration: 0.15)) { showDetails = true }
                        }
                    }
                }
                
                //2. Appearing above screen
                .overlay(alignment: .bottomTrailing) { inviteButton }
                .overlay(alignment: .bottomLeading) { declineButton }
                
                
                //3.Specify coordinate space for measuring
                .coordinateSpace(name: "profileZStack")
            }
        }
        .onAppear { if isUserProfile { vm.viewProfileType = .view } }
        .hideTabBar(hideBar: !ui.isDismissing)
        .overlay(alignment: .bottomTrailing) { inviteButton }
        .overlay(alignment: .bottomLeading) { declineButton }
        .offset(y: isUserProfile ? 0 : ui.profileOffset)
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
    
    //Positioning is controlled by offset as it makes it easier to adjust with details
    private func titleAndImage(geo: GeometryProxy) -> some View {
        VStack(spacing: 24) {
            profileTitle(geo: geo)
                .opacity(interpolate(from: 1, to: 0, impactStart: 0, impactEnd: 0.75))

            ProfileImageView(ui: ui, vm: vm, importedImages: profileImages)
                .overlay(alignment: .topLeading) {
                    overlayTitle(onDismiss: { dismissProfile(using: geo) })
                        .padding(.top, 12)
                        .opacity(interpolate(from: 0, to: 1, impactStart: 0.5, impactEnd: 1))
                        .offset(x: isUserProfile ? 36 : 0)
                }
                .onGeometryChange(for: CGFloat.self) { geo in
                    geo.frame(in: .named("profileZStack")).maxY
                } action: { bottom in
                    guard !ui.hasUpdatedImageBottom else { return }
                    ui.imageBottom = bottom
                    //Stop updating the imageBottom after it stops changing after 0.3 seconds
                    imageBottomSettleTask?.cancel()
                    imageBottomSettleTask = Task {
                        try? await Task.sleep(for: .seconds(0.3))
                        guard !Task.isCancelled else { return }
                        ui.hasUpdatedImageBottom = true
                    }
                }
        }
        .offset(y: interpolate(from: 36, to: -54)) //Logic dealing offset of top part
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private var detailsView: some View {
        ProfileDetailsView(vm: vm, ui: ui, p: vm.profile, event: vm.event)
            .offset(y: ui.detailsOffset)
            .padding(.top, ui.imageBottom + 24) //24 spacing between bottom of image, and start of details
            .scaleEffect(interpolate(from: 0.97, to: 1))
            .simultaneousGesture(detailsDrag)
            .opacity(showDetails || !isMessageProfile ? 1 : 0)
    }

    private var profileBackground: some View {
        UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24) //Bug fix: Critical! Solved the dismissing screen.
            .fill(Color.appCanvas)
            .ignoresSafeArea()
            .customSubtleShadow()
    }
}
