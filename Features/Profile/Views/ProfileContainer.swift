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
    @State var dragStart: CGFloat? = nil   //translation captured on the first drag event so subsequent events grow from 0 instead of jumping by the activation distance

    @Binding var dismissOffset: CGFloat?
    @Binding var selectedProfile: UserProfile?

    @State var ui = ProfileUIState()

    static let toggleAnimation: Animation = .spring(response: 0.32, dampingFraction: 0.86, blendDuration: 0)

    var transition: ProfileDetailsTransition {
        ProfileDetailsTransition(isOpen: ui.detailsOpen, openOffset: ui.detailsOpenOffset, offset: detailsOffset)
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
            ZoomContainer {
                VStack(spacing: 24) {
                    profileTitle(geo: geo)
                        .padding(.top, 36)
                        .opacity(1 - transition.overlayTitleOpacity)
                        .offset(y: transition.interpolate(to: -108))
                    
                    ProfileImageView(vm: vm, importedImages: profileImages)
                        .onTapGesture {closeDetails()}
                        .offset(y: transition.interpolate(to: -100))
                        .simultaneousGesture(imageDetailsDrag(using: geo))

                    ProfileDetailsView(vm: vm, ui: ui, p: displayProfile, event: vm.event)
                        .scaleEffect(transition.interpolate(from: 0.97, to: 1.0), anchor: .top)
                        .onTapGesture {toggleDetails()}
                        .offset(y: detailsOffset)
                        .simultaneousGesture(detailsDrag)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(profileBackground)
                .overlay(alignment: .topLeading) { overlayTitle(onDismiss: { dismissProfile(using: geo) }) }
                .preference(key: OpenDetails.self, value: ui.detailsOpen) //Used to hide profileCloseButton in message container, when details Open
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
    
    private func closeDetails() {
        guard ui.detailsOpen else { return }
        withAnimation(Self.toggleAnimation) {
            ui.detailsOpen = false
            detailsOffset = 0
        }
    }

    private func toggleDetails() {
        withAnimation(Self.toggleAnimation) {
            ui.detailsOpen.toggle()
            detailsOffset = ui.detailsOpen ? ui.detailsOpenOffset : 0
        }
    }
    
    private var profileBackground: some View {
        UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24) //Bug fix: Critical! Solved the dismissing screen.
            .fill(Color.background)
            .ignoresSafeArea()
            .shadow(color: profileOffset > 0 ? .black.opacity(0.25) : .clear, radius: 12, y: 6)
    }
}
