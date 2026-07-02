import SwiftUI
//Note: layout/safe-area context comes from ZoomContainer's own GeometryReader;
//container height for the drag gesture is measured via .onGeometryChange below.

enum ProfileMode {
    case ownProfile(draft: UserProfile)
    case viewProfile
    case sendInvite(onSend: (EventFieldsDraft) -> Void, onDecline: () -> Void)
    case respondToInvite(respondVM: RespondViewModel, onResponse: (ProfileResponse) -> Void)
}

struct ProfileContainer: View {

    // Environment
    @Environment(\.dismiss) var dismiss
    @Environment(ProfileMorphState.self) var morph: ProfileMorphState?

    // State
    @State var vm: ProfileViewModel
    @State var ui = ProfileUIState()
    @State var pendingInvite: (() -> Void)?
    @State var respondUI = RespondPopupUIState()

    let mode: ProfileMode
    let profileImages: [UIImage]
    let onDismiss: (() -> Void)?
    //When starting to dismiss trigger back button to expand (needed for chatContainer)
    let onDismissStart: (() -> Void)?

    var displayProfile: UserProfile {if case .ownProfile(let draft) = mode { draft } else { vm.profile }}

    var displayImages: [UIImage] {
        isUserProfile ? profileImages : vm.images
    }
    
    var isRespondMode: Bool {
        if case .respondToInvite = mode {true} else {false}
    }
    
    var isUserProfile: Bool {
        if case .ownProfile = mode { true } else { false }
    }
    
    init(
        vm: ProfileViewModel,
        profileImages: [UIImage],
        mode: ProfileMode,
        onDismiss: (() -> Void)? = nil,
        onDismissStart: (() -> Void)? = nil,
    ) {
        vm.seed(profileImages)
        _vm = State(initialValue: vm)
        self.profileImages = profileImages
        self.mode = mode
        self.onDismiss = onDismiss
        self.onDismissStart = onDismissStart
    }
    
    var body: some View {
        ZoomContainer {
            ZStack(alignment: .top) {
                titleAndImage
                detailsView
            }
            .background(Color.appCanvas)
            
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                ui.containerHeight = height
            }
            .simultaneousGesture(profileDrag())
            .coordinateSpace(name: "profileZStack")
            .onAppear { if isUserProfile { vm.viewProfileType = .view } }
            .preference(key: ProfileDetailsOpenKey.self, value: ui.detailsOpen)
        }
        .overlay(alignment: .bottomTrailing) { inviteButton }
        .overlay(alignment: .bottomLeading) { declineButton }
        .profileZoomDismiss(ui: ui, enabled: !isUserProfile)
        .quickInvite(
            openPopupId: sendInviteMorphId,
            hideCard: pendingInvite != nil,
            // ProfileContainer already covers the tab bar, so present as an overlay to skip the
            // cover-presentation latency that makes the morph pop in collapsed before opening.
            style: (isRespondMode ? QuickInviteMorphStyle.respond : .send)
                .presentedAsOverlay()
                .tinted(vm.viewProfileType == .invite ? .accent : .appGreen)
                .sideMargin(SendInviteContainer.screenMargin),
            image: { _ in displayImages.first }
        ) { _ in
            sendInviteMorphCard
        } overlay: {
            morphOverlay
        }
    }
}

extension ProfileContainer {
    
    private var titleAndImage: some View {
        VStack(spacing: 24) {
            profileTitle
                .modifier(DetailsFadeEffect(ui: ui, from: 1, to: 0, impactEnd: 0.75))

            ProfileImageView(disableScroll: ui.isDismissDragging, importedImages: displayImages)
                .task { await vm.loadImagesIfNeeded() }
                .overlay(alignment: .topLeading) {overlayTitle}
        }
        .onGeometryChange(for: CGFloat.self) { geo in
            geo.size.height
        } action: { height in
            ui.headerHeight = height
        }
        .padding(.top, ui.headerTopPadding)
        .modifier(ProfileHeaderDragEffect(ui: ui))
    }
    
    private var detailsView: some View {
        ProfileDetailsView(vm: vm, ui: ui, p: displayProfile, event: vm.event)
            .modifier(DetailsCardDragEffect(ui: ui))
            .onGeometryChange(for: CGFloat.self) { geo in
                geo.frame(in: .global).minY
            } action: { minY in
                ui.restingCardTopGlobal = minY
            }
            .padding(.top, ui.detailsRestingTop) //24 spacing between bottom of image, and start of details
    }
}
