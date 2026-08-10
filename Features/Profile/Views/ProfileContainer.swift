import SwiftUI

enum ProfileMode {
    case ownProfile(draft: UserProfile)
    case viewProfile
    case sendInvite(onSend: (EventFieldsDraft) -> Void, onDecline: () -> Void)
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
        .overlay(alignment: .bottomTrailing) { inviteButton }
        .overlay(alignment: .bottomLeading) { declineButton }
        .overlay { inviteOverlay }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
