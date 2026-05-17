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

    @State var dismissOffset: CGFloat = 0

    let mode: ProfileMode
    let profileImages: [UIImage]
    let onDismiss: (() -> Void)?

    var isUserProfile: Bool {
        if case .ownProfile = mode { true } else { false }
    }

    var displayProfile: UserProfile {
        if case .ownProfile(let draft) = mode { draft } else { vm.profile }
    }

    init(
        vm: ProfileViewModel,
        profileImages: [UIImage],
        mode: ProfileMode,
        onDismiss: (() -> Void)? = nil
    ) {
        _vm = State(initialValue: vm)
        self.profileImages = profileImages
        self.mode = mode
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        GeometryReader { geo in
            ZoomContainer {
                ZStack(alignment: .top) {
                    titleAndImage(geo: geo)
                    
                    detailsView
                }
                //1. Profile Background
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(profileBackground)
                
                //2. Appearing above screen
                .overlay(alignment: .bottomTrailing) { inviteButton }
                .overlay(alignment: .bottomLeading) { declineButton }
                
                
                //3.Specify coordinate space for measuring
                .coordinateSpace(name: "profileZStack")
            }
        }
        .overlay { if ui.showPopup { invitePopup } }
        .offset(y: isUserProfile ? 0 : dismissOffset)
        .onAppear { if isUserProfile { vm.viewProfileType = .view } }
        .hideTabBar()
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
                }
                .onGeometryChange(for: CGFloat.self) { geo in
                    geo.frame(in: .named("profileZStack")).maxY
                } action: { bottom in
                    guard !ui.hasUpdatedImageBottom else { return }
                    ui.imageBottom = bottom
                    if bottom > 300 { ui.hasUpdatedImageBottom = true }
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
    }

    private var profileBackground: some View {
        UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24) //Bug fix: Critical! Solved the dismissing screen.
            .fill(Color.background)
            .ignoresSafeArea()
    }
}
