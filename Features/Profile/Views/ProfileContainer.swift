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
    
    @State var isSheetTopAtTarget: Bool = false
    @State var isScrolling: Bool = false
    @State var stopTask: Task<Void, Never>? = nil
    
    var showBackground: Bool {
        isSheetTopAtTarget && !isScrolling
    }
    
    //Temporary edits
    @State var detailsOpen: Bool = false
    @State var profileOffset: CGFloat = 0
    @State var detailsOffset: CGFloat = 0
    
    let detailsOpenOffset: CGFloat = -240
    let detailsClosedOffset: CGFloat = 0
    
    @State var enlargeBackground: Bool = false
    
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
                
                //3. Logic to dismiss the screen
//                .offset(y: profileOffset)
//                .simultaneousGesture(profileDrag)
            }
        }
        .overlay { if ui.showPopup { invitePopup } }
        .offset(y: isUserProfile ? 0 : (dismissOffset ?? 0))
        .onAppear { if isUserProfile { vm.viewProfileType = .view } }
        .hideTabBar()
    }
}

extension ProfileView {
    
    //Positioning is controlled by offset as it makes it easier to adjust with details
    private func titleAndImage(geo: GeometryProxy) -> some View {
        VStack(spacing: 24) {
            profileTitle(geo: geo)
                .opacity(interpolate(from: 1, to: 0))
            
            ProfileImageView(ui: ui, vm: vm, importedImages: profileImages)
                .overlay(alignment: .topLeading) {
                    overlayTitle(onDismiss: { dismissProfile(using: geo) })
                        .padding(.top, 12)
                        .opacity(interpolate(from: 0, to: 1))
                }
        }
        .offset(y: interpolate(from: 36, to: -54)) //Logic dealing offset of top part
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private var detailsView: some View {
        ProfileDetailsView(vm: vm, ui: ui, p: vm.profile, event: vm.event)
            .offset(y: detailsOffset)
            .padding(.top, 572)
            .scaleEffect(interpolate(from: 0.97, to: 1))
            .highPriorityGesture(detailsDrag.exclusively(before: profileDrag))
    }
    
    private var profileBackground: some View {
        UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24) //Bug fix: Critical! Solved the dismissing screen.
            .fill(Color.background)
            .ignoresSafeArea()
            .shadow(color: profileOffset > 0 ? .black.opacity(0.25) : .clear, radius: 12, y: 6)
    }
}


/*
 .padding(.top, 36)
 .padding(.top, detailsOpen ? -6 : 0)
 .offset(y: interpolate(from: 0, to: -78)) //-36 for topPadding,
 */
