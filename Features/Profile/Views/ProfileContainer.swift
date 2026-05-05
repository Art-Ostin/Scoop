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

    let mode: ProfileMode
    let profileImages: [UIImage]

    @State var detailsOffset: CGFloat = 0
    @State var profileOffset: CGFloat = 0
    @State var dragType: DragType? = nil

    @Binding var dismissOffset: CGFloat?
    @Binding var selectedProfile: UserProfile?

    @State var ui = ProfileUIState()

    static let toggleAnimation: Animation = .spring(response: 0.32, dampingFraction: 0.86, blendDuration: 0)

    var transition: ProfileDetailsTransition {
        ProfileDetailsTransition(isOpen: ui.detailsOpen, openOffset: ui.detailsOpenOffset, dragOffset: detailsOffset)
    }

    var isUserProfile: Bool {
        if case .ownProfile = mode { return true }
        return false
    }

    var displayProfile: UserProfile {
        if case .ownProfile(let draft) = mode { return draft }
        return vm.profile
    }

    init(
        vm: ProfileViewModel,
        profileImages: [UIImage],
        selectedProfile: Binding<UserProfile?>,
        dismissOffset: Binding<CGFloat?>,
        mode: ProfileMode
    ) {
        _vm = State(initialValue: vm)
        self.profileImages = profileImages
        _selectedProfile = selectedProfile
        _dismissOffset = dismissOffset
        self.mode = mode
    }
    
    var body: some View {
        GeometryReader { geo in
            if !ui.hideProfileScreen {
                ZoomContainer {
                    VStack(spacing: 24) {
                        profileTitle(geo: geo)
                            .offset(y: transition.interpolate(to: -108))
                            .opacity(1 - transition.overlayTitleOpacity)
                            .padding(.top, 36)

                        ProfileImageView(vm: vm, importedImages: profileImages)
                            .offset(y: transition.interpolate(to: -100))
                            .simultaneousGesture(imageDetailsDrag(using: geo))
                            .onTapGesture {
                                if ui.detailsOpen {
                                    withAnimation(Self.toggleAnimation) { ui.detailsOpen = false }
                                }
                            }

                        ProfileDetailsView(vm: vm, ui: ui, p: displayProfile, event: vm.event)
                            .scaleEffect(transition.interpolate(from: 0.97, to: 1.0), anchor: .top)
                            .offset(y: transition.sectionOffset)
                            .onTapGesture {
                                withAnimation(Self.toggleAnimation) { ui.detailsOpen.toggle() }
                            }
                            .simultaneousGesture(detailsDrag)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(profileBackground)
                    .overlay(alignment: .topLeading) { overlayTitle(onDismiss: { dismissProfile(using: geo) }) }
                    .preference(key: OpenDetails.self, value: ui.detailsOpen)
                }
            }
        }
        .overlay {if ui.showPopup{invitePopup}}
        .offset(y: isUserProfile ? 0 : activeProfileOffset)
        .onAppear { if isUserProfile {vm.viewProfileType = .view } }
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottomTrailing) {inviteButton}
        .overlay(alignment: .bottomLeading) {declineButton}
        .hideTabBar()
    }
}
