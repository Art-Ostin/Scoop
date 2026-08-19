import SwiftUI

enum ProfileMode {
    case ownProfile(draft: UserProfile, showsSaveButton: Bool)
    case viewProfile
    //onDecline carries the decline button's global frame when the tap had one to measure —
    //the response cover's cross launches from it (nil launches from the cover's fallback spot).
    //onSend likewise carries the card image the tap lifted off from — the send cover's hero
    //flight starts there (nil degrades the cover to its flightless fade-in).
    case sendInvite(onSend: (EventFieldsDraft, SendInviteFlightSource?) -> Void, onDecline: (CGRect?) -> Void)
    case respondToInvite(respondVM: RespondViewModel, onResponse: (ProfileResponse) -> Void)
}

struct ProfileContainer: View {

    //Injected
    @Environment(\.dismiss) var dismiss
    @Environment(\.zoomDismiss) var zoomDismiss
    @State var vm: ProfileViewModel
    let mode: ProfileMode
    let profileImages: [UIImage]

    //Local view state
    @State var ui = ProfileUIState()

    var displayProfile: UserProfile {if case .ownProfile(let draft, _) = mode { draft } else { vm.profile }}

    var showsSaveButton: Bool {
        if case .ownProfile(_, let shows) = mode { shows } else { false }
    }

    var displayImages: [UIImage] {
        isUserProfile ? profileImages : vm.images
    }

    var isUserProfile: Bool {
        if case .ownProfile = mode { true } else { false }
    }

    init(
        vm: ProfileViewModel,
        profileImages: [UIImage],
        mode: ProfileMode
    ) {
        vm.seed(profileImages)
        _vm = State(initialValue: vm)
        self.profileImages = profileImages
        self.mode = mode
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                profileTitle
                
                ProfileImageView(disableScroll: false, images: displayImages, isUserProfile: isUserProfile, selectedIndex: $ui.selectedImageIndex)
                    .task { await vm.loadImagesIfNeeded() }

                ProfileDetailsView(vm: vm, p: displayProfile, event: vm.event)
            }
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.clearance)
        }
        .scrollIndicators(.hidden)
        .background(Color.appCanvas)
        .onAppear { if isUserProfile { vm.viewProfileType = .view } }
        .overlay(alignment: .trailing) { inviteButton }
        .overlay(alignment: .leading) { declineButton.padding(.top, 24)}
        .overlay { inviteOverlay }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
