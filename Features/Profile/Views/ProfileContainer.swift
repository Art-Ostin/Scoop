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
    @State var detailsFullyOpen: Bool = false   //published to ChatHeaderBar via OpenDetails preference. Updated only after the open/close animation finishes so the parent's re-render doesn't drop a frame mid-spring.

    @Binding var dismissOffset: CGFloat?
    @Binding var selectedProfile: UserProfile?

    @State var ui = ProfileUIState()

    static let toggleAnimation: Animation = .spring(duration: 0.4, bounce: 0.1)

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
                        .scaleEffect(transition.interpolate(from: 0.97, to: 1), anchor: .top)
                        .onTapGesture {toggleDetails()}
                        .offset(y: detailsOffset)
                        .simultaneousGesture(detailsDrag)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(profileBackground)
                .overlay(alignment: .topLeading) { overlayTitle(onDismiss: { dismissProfile(using: geo) }) }
                .preference(key: OpenDetails.self, value: detailsFullyOpen) //Used to hide profileCloseButton in message container, when details Open
            }
        }
        .overlay {if ui.showPopup{invitePopup}}
        .offset(y: isUserProfile ? 0 : activeProfileOffset)
        .onAppear {
            if isUserProfile { vm.viewProfileType = .view }
        }
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottomTrailing) {inviteButton}
        .overlay(alignment: .bottomLeading) {declineButton}
        .hideTabBar()
    }

    private func closeDetails() {
        guard ui.detailsOpen else { return }
        ui.detailsOpen = false   //flipped outside withAnimation so SwiftUI doesn't enroll every dependent view (colors, scrollDisabled, dismiss button visibility, etc.) in the animation transaction. Only detailsOffset is animated; transition.interpolate(...) stays continuous because it derives from both isOpen and the animated offset.
        withAnimation(Self.toggleAnimation) {
            detailsOffset = 0
        } completion: {
            detailsFullyOpen = false
        }
    }

    private func toggleDetails() {
        ui.detailsOpen.toggle()
        withAnimation(Self.toggleAnimation) {
            detailsOffset = ui.detailsOpen ? ui.detailsOpenOffset : 0
        } completion: {
            detailsFullyOpen = ui.detailsOpen
        }
    }
    
    private var profileBackground: some View {
        UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24) //Bug fix: Critical! Solved the dismissing screen.
            .fill(Color.background)
            .ignoresSafeArea()
            .shadow(color: profileOffset > 0 ? .black.opacity(0.25) : .clear, radius: 12, y: 6)
    }
}
