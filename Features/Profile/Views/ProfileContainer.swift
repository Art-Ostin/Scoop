import SwiftUI
//Note: Geometry Reader needed to Keep the VStack from respecting the top safe Area


enum ProfileMode {
    case ownProfile(draft: UserProfile)
    case viewProfile
    case sendInvite(onSend: (EventFieldsDraft) -> Void)
    case respondToInvite(respondVM: RespondViewModel, onResponse: (ProfileResponse) -> Void)
}

struct ProfileView: View {

    @Environment(\.dismiss) var dismiss
    @State var vm: ProfileViewModel

    let mode: ProfileMode
    let profileImages: [UIImage]

    @GestureState var detailsOffset = CGFloat.zero
    @GestureState var profileOffset = CGFloat.zero

    @Binding var dismissOffset: CGFloat?
    @Binding var selectedProfile: UserProfile?

    @State var ui = ProfileUIState()

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

                        ProfileImageView(vm: vm, detailsOffset: detailsOffset, importedImages: profileImages)
                            .offset(y: transition.interpolate(to: -100))
                            .simultaneousGesture(imageDetailsDrag(using: geo))
                            .onTapGesture { if ui.detailsOpen { ui.detailsOpen.toggle()}}

                        ProfileDetailsView(vm: vm, ui: ui, p: displayProfile, detailsOffset: detailsOffset, event: vm.event)
                            .scaleEffect(transition.interpolate(from: 0.97, to: 1.0), anchor: .top)
                            .offset(y: transition.sectionOffset)
                            .onTapGesture { ui.detailsOpen.toggle() }
                            .simultaneousGesture(detailsDrag)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(profileBackground)
                    .animation(.spring(duration: 0.2), value: ui.detailsOpen)
                    .animation(.easeInOut(duration: 0.2), value: detailsOffset)
                    .animation(.snappy(duration: ui.dismissalDuration), value: profileOffset) //Bug Fix: ProfileOffset & selected profile Must be same animation length
                    .animation(.easeInOut(duration: ui.dismissalDuration), value: selectedProfile) //snappy(duration: ui.dismissalDuration)
                    .overlay(alignment: .topLeading) { overlayTitle(onDismiss: { dismissProfile(using: geo) }) }
                    .preference(key: OpenDetails.self, value: ui.detailsOpen)
                }
            }
        }
        .overlay {if ui.showRespondPopup {invitePopup}}
        .offset(y: isUserProfile ? 0 : activeProfileOffset)
        .onAppear { if isUserProfile {vm.viewProfileType = .view } }
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottomTrailing) {
            if showInviteButton {
                InviteButton(vm: vm, showInvite: $ui.showRespondPopup)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 144)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if vm.viewProfileType == .invite {
                EventDeclineButton() { } //EMPTY DECLINE HERE
                    .opacity(ui.showRespondPopup ? 0 : 1)
            }
        }
        .hideTabBar()
    }
    
    private var showInviteButton: Bool {
        return vm.viewProfileType != .view && vm.viewProfileType != .accepted && !ui.showRespondPopup
    }
}
