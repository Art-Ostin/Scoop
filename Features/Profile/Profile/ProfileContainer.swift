import SwiftUI
//Note: Geometry Reader needed to Keep the VStack from respecting the top safe Area

struct ProfileView: View {
    @Environment(\.tabSelection) private var tabSelection
    @Environment(\.dismiss) private var dismiss
    
    @State private var vm: ProfileViewModel
    let meetVM: MeetViewModel?
    
    @GestureState var detailsOffset = CGFloat.zero
    @GestureState var profileOffset = CGFloat.zero
    @Binding private var dismissOffset: CGFloat?
    @Binding var showRespondToProfile: Bool?
    @Binding private var selectedProfile: ProfileModel?

    @State private var ui = ProfileUIState()
    private var detailsDragRange: ClosedRange<CGFloat> {
        let limit = ui.detailsOpenOffset - 80
        return ui.detailsOpen ? (-85 ... -limit) : (limit ... 85)
    }
    let profileImages: [UIImage]

    //Functionality to do with draftProfile to display
    let draftProfile: UserProfile?
    var isUserProfile: Bool { draftProfile != nil }
    
    private var displayProfile: UserProfile {
        draftProfile ?? vm.profileModel.profile
    }
    
    init(vm: ProfileViewModel, meetVM: MeetViewModel? = nil, profileImages: [UIImage], selectedProfile: Binding<ProfileModel?>, dismissOffset: Binding<CGFloat?>, showRespondToProfile: Binding<Bool?> = .constant(nil), draftProfile: UserProfile? = nil) {
        _vm = State(initialValue: vm)
        self.meetVM = meetVM
        self.profileImages = profileImages
        _selectedProfile = selectedProfile
        _dismissOffset = dismissOffset
        self.draftProfile = draftProfile
        self._showRespondToProfile = showRespondToProfile
    }
    
    var body: some View {
        GeometryReader { geo in
            if !ui.hideProfileScreen {
                ZoomContainer {
                    VStack(spacing: 24) {
                        profileTitle(geo: geo)
                            .offset(y: rangeUpdater(endValue: -108))
                            .opacity(1 - overlayTitleOpacity)
                            .padding(.top, 36)
                        
                        ProfileImageView(vm: vm, showInvite: $ui.showInvitePopup, detailsOffset: detailsOffset, importedImages: profileImages)
                            .offset(y: rangeUpdater(endValue: -100))
                            .simultaneousGesture(imageDetailsDrag(using: geo))
                            .onTapGesture { if ui.detailsOpen { ui.detailsOpen.toggle()}}
                        
                        ProfileDetailsView(vm: vm, isTopOfScroll: $ui.isTopOfScroll, showInvite: $ui.showInvitePopup, detailsOpen: ui.detailsOpen, detailsOffset: detailsOffset, p: displayProfile) { dismissProfileWithAction(invited: false)}
                            .scaleEffect(rangeUpdater(startValue: 0.97, endValue: 1.0), anchor: .top)
                            .offset(y: detailsSectionOffset())
                            .onTapGesture { ui.detailsOpen.toggle() }
                            .simultaneousGesture(detailsDrag)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(
                        UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24) //Bug fix: Critical! Solved the dismissing screen.
                            .fill(Color.background)
                            .ignoresSafeArea()
                            .shadow(color: profileOffset.isZero ? Color.clear : .black.opacity(0.25), radius: 12, y: 6)
                    )
                    .animation(.spring(duration: 0.2), value: ui.detailsOpen)
                    .animation(.easeInOut(duration: 0.2), value: detailsOffset)
                    .animation(.snappy(duration: ui.dismissalDuration), value: profileOffset) //Bug Fix: ProfileOffset & selected profile Must be same animation length
                    .animation(.easeInOut(duration: ui.dismissalDuration), value: selectedProfile) /*snappy(duration: ui.dismissalDuration)*/
                    .overlay(alignment: .topLeading) { overlayTitle(onDismiss: { dismissProfile(using: geo) }) }
                }
            }
        }
        .overlay {if ui.showInvitePopup {invitePopup}}
        .offset(y: isUserProfile ? 0 : activeProfileOffset)
        .onAppear { if isUserProfile {vm.viewProfileType = .view } }
    }
}

//Different Screens
extension ProfileView {
    @ViewBuilder
    private var invitePopup: some View {
        if ui.showInvitePopup, let event = vm.profileModel.event {
            AcceptInvitePopup(profileModel: vm.profileModel) {
                if let meetVM {
                    @Bindable var meetVM = meetVM
                    Task {
                        do {
                            try await meetVM.acceptInvite(profileModel: vm.profileModel, userEvent: event)
                            await MainActor.run { withAnimation { tabSelection.wrappedValue = 1 } }
                        } catch {
                            print("Error sending invite: \(error)")
                        }
                    }
                }
            }
        } else {
            SelectTimeAndPlace(defaults: vm.defaults, sessionManager: vm.s, profile: vm.profileModel, onDismiss: { ui.showInvitePopup = false }) { event in
                dismissProfileWithAction(invited: true, event: event)
            }
        }
    }
    
    private func profileTitle(geo: GeometryProxy) -> some View {
        HStack {
            Text(displayProfile.name)
            ForEach (displayProfile.nationality, id: \.self) {flag in Text(flag)}
            Spacer()
            if !isUserProfile {
                ProfileDismissButton(color: .black, selectedProfile: $selectedProfile) {dismissProfile(using: geo)}
            }
        }
        .offset(y: 4) // Hack to align to bottom of HStack
        .font(.body(24, .bold))
        .padding(.horizontal)
    }
    
    private func overlayTitle(onDismiss: @escaping () -> Void) -> some View {
        HStack {
            Text(displayProfile.name)
            Spacer()
            if !isUserProfile {
                ProfileDismissButton(color: .white, selectedProfile: $selectedProfile) { onDismiss() }
                    .padding(6)
                    .glassIfAvailable(Circle())
            }
        }
        .font(.body(24, .bold))
        .contentShape(Rectangle())
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .opacity(overlayTitleOpacity)
    }
}

//Details Open or Closed Animations
extension ProfileView {
    func detailsSectionOffset() -> CGFloat {
        return detailsOffset + (ui.detailsOpen ? ui.detailsOpenOffset : 0)
    }
    
    private var overlayTitleOpacity: Double {
        let oneThird = max(1, abs(ui.detailsOpenOffset) / 3)
        let offsetProgress = abs(detailsOffset)
        if ui.detailsOpen {
            guard offsetProgress < oneThird else { return 0 }
            return 1 - min(detailsOffset / oneThird, 1)
        }
        guard offsetProgress >= oneThird else { return 0 }
        return max((offsetProgress - oneThird) / oneThird, 0)
    }
    
    func rangeUpdater(startValue: CGFloat = 0, endValue: CGFloat) -> CGFloat {
        let denom = max(abs(ui.detailsOpenOffset), 0.0001)
        let t = min(abs(detailsOffset) / denom, 1)
        let delta = (endValue - startValue) * t
        let baseValue = ui.detailsOpen ? endValue : startValue
        let adjustForDrag = (ui.detailsOpen && detailsOffset > 0) || (!ui.detailsOpen && detailsOffset < 0)
        return adjustForDrag ? (ui.detailsOpen ? (baseValue - delta) : (baseValue + delta)) : baseValue
    }
}

//Drag Gestures
extension ProfileView {
    private func imageDetailsDrag(using geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .updating($profileOffset) { value, state, _ in
                if ui.dragType == nil { dragType(v: value) }
                guard ui.dragType == .profile else { return }
                state = value.translation.height
            }
            .updating($detailsOffset) { v, state, _ in
                if ui.dragType == nil { dragType(v: v) }
                guard ui.dragType == .details else { return }
                state = v.translation.height.clamped(to: detailsDragRange)
            }
            .onEnded { v in
                defer { ui.dragType = nil }
                guard ui.dragType != nil && ui.dragType != .horizontal else { return }
                let predicted = abs(v.predictedEndTranslation.height)
                let distance = abs(v.translation.height)
                //Only update if user drags more than 75
                guard max(distance, predicted) > 75 else { return }
                if ui.dragType == .profile {
                    dismissOffset = v.translation.height
                    
                    if meetVM != nil { //Bug Fix: Causes issues with the selectedProfile
                        selectedProfile = nil
                    } else {
                        withAnimation(.easeInOut(duration: ui.dismissalDuration)) { selectedProfile = nil }
                    }
                } else if ui.dragType == .details {
                    ui.detailsOpen.toggle()
                }
            }
    }
    
    private var detailsDrag: some Gesture {
        DragGesture(minimumDistance: 5)
            .updating($detailsOffset) { v, state, _ in
                if ui.detailsOpen && (!ui.isTopOfScroll || v.translation.height < 0) { return }
                if ui.dragType == nil {dragType(v: v)}
                guard ui.dragType != nil && ui.dragType != .horizontal else { return }
                state = v.translation.height.clamped(to: detailsDragRange)
            }
            .onEnded {
                defer { ui.dragType = nil }
                guard ui.dragType != nil && ui.dragType != .horizontal else { return }
                let predicted = $0.predictedEndTranslation.height
                if predicted < 50 && profileOffset == 0 {
                    ui.detailsOpen = true
                } else if ui.detailsOpen && predicted > 60 {
                    ui.detailsOpen = false
                }
            }
    }
    
    private func dragType(v: DragGesture.Value) {
        //If there is already a dragType don't reassign it (here), get y and x drag
        if ui.dragType != nil  {return }
        let dy = abs(v.translation.height)
        let dx = abs(v.translation.width)
        //Ensures user drags at least 5 points, and its a vertical drag
        guard dy > dx else { ui.dragType = .horizontal; return}
        //If it passes conditions updates 'drag type'
        ui.dragType = (v.translation.height < 0 || ui.detailsOpen) ? .details : .profile
    }
}

//Dismissing Profile
extension ProfileView {
    
    private var activeProfileOffset: CGFloat {
        dismissOffset ?? profileOffset
    }
    
    private func dismissProfile(using geo: GeometryProxy, startingOffset: CGFloat? = nil) {
        dismiss()
        let distance = geo.size.height + geo.safeAreaInsets.bottom
        if let startingOffset {
            dismissOffset = startingOffset
        }
        withAnimation(.snappy(duration: ui.dismissalDuration)) {
            dismissOffset = distance
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ui.dismissalDuration) {
            selectedProfile = nil
        }
    }
    
    private func dismissProfileWithAction(invited: Bool, event: EventDraft? = nil) {
        showRespondToProfile = invited
        
        Task { @MainActor in
            //1. Set up 625 millisecond minimum time for dismiss screen to show
            async let minDelay: Void = Task.sleep(for: .milliseconds(625))
            
            //2.Dismiss profile in background after 250 milliseconds
            try? await Task.sleep(for: .milliseconds(100))
            selectedProfile = nil
            
            //3.Either Invite or decline the profile (Uncomment when actual done
            if invited {
                guard let event else {return}
                print("Would have invited")
                /*
                 try? await meetVM?.updateProfileRec(event: event, profileModel: vm.profileModel, status: .invited)
                 */
            } else {
                print("Would have declined")
                /*
                 try? await meetVM?.updateProfileRec(profileModel: vm.profileModel, status: .declined)
                 */
            }
            //4. If at least 625 milliseconds have past, dismiss the screenCover
            try? await minDelay //ensures at least 625 milliseconds have past
            withAnimation(.easeInOut(duration: 0.2)) {showRespondToProfile = nil}
        }
    }
}


