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
    
    @Binding var dismissOffset: CGFloat?
    @Binding var selectedProfile: UserProfile?
    
    let mode: ProfileMode
    let profileImages: [UIImage]
    
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
                    if !ui.detailOpen {
                        profileTitle(geo: geo)
                            .padding(.top, 36)
                    }
                    
                    ProfileImageView(ui: ui, vm: vm, importedImages: profileImages)
                            .padding(.top, ui.detailOpen ? -12 : 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(profileBackground)
                .overlay(alignment: .topLeading) { overlayTitle(onDismiss: { dismissProfile(using: geo) }) }
//                .offset(y: ui.detailOpen ? -172 : 0)
                .animation(.spring(response: 0.32, dampingFraction: 0.86), value: ui.detailOpen)
                .sheet(isPresented: .constant(true)) { detailsSheet }
            }
        }
        .overlay { if ui.showPopup { invitePopup } }
        .offset(y: isUserProfile ? 0 : (dismissOffset ?? 0))
        .onAppear { if isUserProfile { vm.viewProfileType = .view } }
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottomTrailing) { inviteButton }
        .overlay(alignment: .bottomLeading) { declineButton }
        .hideTabBar()
    }
    
    private var profileBackground: some View {
        UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24) //Bug fix: Critical! Solved the dismissing screen.
            .fill(Color.background)
            .ignoresSafeArea()
    }
    
    private var detailsSheet: some View {
        ProfileDetailsView(vm: vm, ui: ui, p: displayProfile, event: vm.event)
            .presentationDetents([.fraction(0.26), .fraction(0.65)], selection: $ui.selectedDetent)
            .presentationBackgroundInteraction(.enabled)
            .interactiveDismissDisabled(true)
            .presentationCompactAdaptation(.sheet)
            .presentationBackground(Color.clear)
            .presentationDragIndicator(.hidden)
    }

    func dismissProfile(using geo: GeometryProxy) {
        let distance = geo.size.height + geo.safeAreaInsets.bottom
        withAnimation(.snappy(duration: ui.dismissDuration)) {
            dismissOffset = distance
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ui.dismissDuration) {
            selectedProfile = nil
        }
    }
}
