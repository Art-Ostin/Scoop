import SwiftUI

enum ProfileMode {
    case ownProfile(draft: UserProfile)
    case viewProfile
    case sendInvite(onSend: (EventFieldsDraft) -> Void, onDecline: () -> Void)
    case respondToInvite(respondVM: RespondViewModel, onResponse: (ProfileResponse) -> Void)
}

//One plain scrollable surface: title, image pager, details sections inline.
//Dismissal: zoom-presented profiles use the native drag (plus the chevron);
//morph-presented profiles (Events/Chat/Invites) close via the chevron, which
//still runs the reverse-zoom render (profileZoomDismiss + morph).
struct ProfileContainer: View {

    //Injected
    @Environment(\.dismiss) var dismiss
    @Environment(ProfileMorphState.self) var morph: ProfileMorphState?
    @Environment(\.zoomPresented) var zoomPresented //ImageZoom presentation: the native drag owns dismissal
    @State var vm: ProfileViewModel
    let mode: ProfileMode
    let profileImages: [UIImage]
    let onDismiss: (() -> Void)?
    let onDismissStart: (() -> Void)? //When starting to dismiss trigger back button to expand (needed for ChatContainer)

    //Local view state
    @State var ui = ProfileUIState()
    @State var invite = SendInvitePresenter() //Owns the invite card's open/close flight, presented above this profile

    var displayProfile: UserProfile {if case .ownProfile(let draft) = mode { draft } else { vm.profile }}

    var displayImages: [UIImage] {
        isUserProfile ? profileImages : vm.images
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
        ScrollView {
            VStack(spacing: Spacing.lg) {
                profileTitle

                ProfileImageView(disableScroll: false, images: displayImages, selectedIndex: $ui.selectedImageIndex, inviteSourceID: vm.profile.id)
                    .task { await vm.loadImagesIfNeeded() }

                ProfileDetailsView(vm: vm, p: displayProfile, event: vm.event)
            }
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.clearance)
        }
        .scrollIndicators(.hidden)
        .background(Color.appCanvas)
        .onAppear { if isUserProfile { vm.viewProfileType = .view } }
        .overlay(alignment: .bottomTrailing) { inviteButton }
        .overlay(alignment: .bottomLeading) { declineButton }
        .profileZoomDismiss(ui: ui, enabled: !isUserProfile && !zoomPresented) //Reverse-zoom render for the morph close
        .overlay { inviteOverlay } //Above the zoom-dismissed profile — the card is its own surface
        .environment(invite) //So the hero image's .sendInviteSource reports its frame as the flight origin
    }
}
