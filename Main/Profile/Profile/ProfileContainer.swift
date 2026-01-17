import SwiftUI
//Note: Geometry Reader needed to Keep the VStack from respecting the top safe Area

struct ProfileView: View {
    @Environment(\.tabSelection) private var tabSelection
    @Environment(\.dismiss) private var dismiss
    
    @GestureState var detailsOffset = CGFloat.zero
    @GestureState var profileOffset = CGFloat.zero
    @Binding private var dismissOffset: CGFloat?
    
    @State private var vm: ProfileViewModel
    let meetVM: MeetViewModel?
    
    @State private var showInvitePopup: Bool = false
    @State private var detailsOpen: Bool = false
    @State private var dragType: DragType? = nil
    @State private var isTopOfScroll = true
    @State private var detailsOpenOffset: CGFloat = -284
    @State private var showDeclineScreen: Bool = false
    @State private var hideProfileScreen: Bool = false
    
    @Binding private var selectedProfile: ProfileModel?
    @State var isUserProfile: Bool
    @State private var containerHeight: CGFloat = 0
    
    private let dismissalDuration: TimeInterval = 0.35
    
    private var detailsDragRange: ClosedRange<CGFloat> {
        let limit = detailsOpenOffset - 80
        return detailsOpen ? (-85 ... -limit) : (limit ... 85)
    }
    
    let profileImages: [UIImage]
    
    init(vm: ProfileViewModel, meetVM: MeetViewModel? = nil, profileImages: [UIImage], selectedProfile: Binding<ProfileModel?>, dismissOffset: Binding<CGFloat?>, isUserProfile: Bool = false) {
        _vm = State(initialValue: vm)
        self.meetVM = meetVM
        self.profileImages = profileImages
        _selectedProfile = selectedProfile
        _dismissOffset = dismissOffset
        self.isUserProfile = isUserProfile
    }
    
    var body: some View {
        GeometryReader { geo in
            ZoomContainer {
                VStack(spacing: 24) {
                    profileTitle(geo: geo)
                        .offset(y: rangeUpdater(endValue: -108))
                        .opacity(1 - overlayTitleOpacity)
                        .padding(.top, 36)
                    
                    ProfileImageView(vm: vm, showInvite: $showInvitePopup, detailsOffset: detailsOffset, importedImages: profileImages)
                        .offset(y: rangeUpdater(endValue: -100))
                        .simultaneousGesture(imageDetailsDrag)
                        .onTapGesture { if detailsOpen { detailsOpen.toggle()}}
                    
                    ProfileDetailsView(vm: vm, isTopOfScroll: $isTopOfScroll, showInvite: $showInvitePopup, detailsOpen: detailsOpen, detailsOffset: detailsOffset, p: vm.profileModel.profile) { onDecline() }
                        .scaleEffect(rangeUpdater(startValue: 0.97, endValue: 1.0), anchor: .top)
                        .offset(y: detailsSectionOffset())
                        .onTapGesture { detailsOpen.toggle() }
                        .simultaneousGesture(detailsDrag)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(
                    //Do not Change Critical! Fixed the scrolling down issue
                    UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                        .fill(Color.background)
                        .ignoresSafeArea()
                        .shadow(color: profileOffset.isZero ? Color.clear : .black.opacity(0.25), radius: 12, y: 6)
                )
                .animation(.spring(duration: 0.2), value: detailsOpen)
                .animation(.easeInOut(duration: 0.2), value: detailsOffset)
                .animation(.snappy(duration: 0.35), value: profileOffset)//Bug Fix: ProfileOffset & selected profile Must be same animation length
                .animation(.snappy(duration: 0.35), value: selectedProfile)
                .overlay(alignment: .topLeading) { overlayTitle(onDismiss: { dismissProfile(using: geo) }) }
            }
        }
        .transition( .move(edge: .bottom))
        .overlay {if showInvitePopup {invitePopup}}
        .overlay { if showDeclineScreen { declineScreen} }
        .offset(y: isUserProfile ? 0 : activeProfileOffset)
    }
}

//Different Screens
extension ProfileView {
    @ViewBuilder
    private var invitePopup: some View {
        if showInvitePopup, let event = vm.profileModel.event {
            AcceptInvitePopup(profileModel: vm.profileModel) {
                if let meetVM {
                    @Bindable var meetVM = meetVM
                    Task { try? await meetVM.acceptInvite(profileModel: vm.profileModel, userEvent: event) }
                    tabSelection.wrappedValue = 1
                }
            }
        } else if let meetVM {
            SelectTimeAndPlace(profile: vm.profileModel, onDismiss: { showInvitePopup = false }) { event in
                try? await meetVM.sendInvite(event: event, profileModel: vm.profileModel)
            }
        }
    }
    
    private func profileTitle(geo: GeometryProxy) -> some View {
        HStack {
            Text(vm.profileModel.profile.name)
            ForEach (vm.profileModel.profile.nationality, id: \.self) {flag in Text(flag)}
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
            Text(vm.profileModel.profile.name)
            Spacer()
            ProfileDismissButton(color: .white, selectedProfile: $selectedProfile) { onDismiss() }
                .padding(6)
                .glassIfAvailable(Circle())
        }
        .font(.body(24, .bold))
        .contentShape(Rectangle())
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .opacity(overlayTitleOpacity)
    }
    
    private var declineScreen: some View {
        ZStack  {
            VStack(alignment: .center, spacing: 36) {
                Image("Monkey")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                
                Text("Declined")
                    .font(.body(16, .bold))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color.background)
        .onTapGesture { showDeclineScreen.toggle() }
    }
}

//Details Open or Closed Animations
extension ProfileView {
    func detailsSectionOffset() -> CGFloat {
        return detailsOffset + (detailsOpen ? detailsOpenOffset : 0)
    }
    
    private var overlayTitleOpacity: Double {
        let oneThird = max(1, abs(detailsOpenOffset) / 3)
        let offsetProgress = abs(detailsOffset)
        if detailsOpen {
            guard offsetProgress < oneThird else { return 0 }
            return 1 - min(detailsOffset / oneThird, 1)
        }
        guard offsetProgress >= oneThird else { return 0 }
        return max((offsetProgress - oneThird) / oneThird, 0)
    }
    
    func rangeUpdater(startValue: CGFloat = 0, endValue: CGFloat) -> CGFloat {
        let denom = max(abs(detailsOpenOffset), 0.0001)
        let t = min(abs(detailsOffset) / denom, 1)
        let delta = (endValue - startValue) * t
        let baseValue = detailsOpen ? endValue : startValue
        let adjustForDrag = (detailsOpen && detailsOffset > 0) || (!detailsOpen && detailsOffset < 0)
        return adjustForDrag ? (detailsOpen ? (baseValue - delta) : (baseValue + delta)) : baseValue
    }
}

//Drag Gestures
extension ProfileView {
    private var imageDetailsDrag: some Gesture {
        DragGesture(minimumDistance: 5)
            .updating($profileOffset) { value, state, _ in
                if dragType == nil { dragType(v: value) }
                guard dragType == .profile else { return }
                state = value.translation.height
            }
            .updating($detailsOffset) { v, state, _ in
                if dragType == nil { dragType(v: v) }
                guard dragType == .details else { return }
                state = v.translation.height.clamped(to: detailsDragRange)
            }
            .onEnded { v in
                defer { dragType = nil }
                guard dragType != nil && dragType != .horizontal else { return }
                let predicted = abs(v.predictedEndTranslation.height)
                let distance = abs(v.translation.height)
                //Only update if user drags more than 75
                guard max(distance, predicted) > 75 else { return }
                if dragType == .profile {
                    dismissOffset = v.translation.height
                    selectedProfile = nil
                } else if dragType == .details {
                    detailsOpen.toggle()
                }
            }
    }
    
    private var detailsDrag: some Gesture {
        DragGesture(minimumDistance: 5)
            .updating($detailsOffset) { v, state, _ in
                if detailsOpen && (!isTopOfScroll || v.translation.height < 0) { return }
                if dragType == nil {dragType(v: v)}
                guard dragType != nil && dragType != .horizontal else { return }
                state = v.translation.height.clamped(to: detailsDragRange)
            }
            .onEnded {
                defer { dragType = nil }
                guard dragType != nil && dragType != .horizontal else { return }
                let predicted = $0.predictedEndTranslation.height
                if predicted < 50 && profileOffset == 0 {
                    detailsOpen = true
                } else if detailsOpen && predicted > 60 {
                    detailsOpen = false
                }
            }
    }
    
    private func dragType(v: DragGesture.Value) {
        //If there is already a dragType don't reassign it (here), get y and x drag
        if self.dragType != nil  {return }
        let dy = abs(v.translation.height)
        let dx = abs(v.translation.width)
        //Ensures user drags at least 5 points, and its a vertical drag
        guard dy > dx else { dragType = .horizontal; return}
        //If it passes conditions updates 'drag type'
        self.dragType = (v.translation.height < 0 || detailsOpen) ? .details : .profile
    }
}

//Other
extension ProfileView {
    
    private var activeProfileOffset: CGFloat {
        dismissOffset ?? profileOffset
    }
    
    private func dismissProfile(using geo: GeometryProxy) {
        dismiss()
        let distance = geo.size.height + geo.safeAreaInsets.bottom
        withAnimation(.snappy(duration: dismissalDuration)) {
            dismissOffset = distance
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissalDuration) {
            selectedProfile = nil
        }
    }

    
    private func onDecline() {
        showDeclineScreen = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {hideProfileScreen = true}
        Task {
            //       try await meetVM?.declineProfile(profileModel: pModel)
            try await Task.sleep(nanoseconds: 750_000_000)
            await MainActor.run { withAnimation(.easeInOut(duration: 0.3)) { selectedProfile = nil} }
        }
    }
}

//IT is the dismiss offset that is causing the bug for it to reappear. When I click on the screen quickly again, there is already a dismiss offset causing the issue.

// The two different offset speeds on the profile: (1) ProfileOffset (animation) sometimes is causing the profile to dismiss at a particular speed (2) Sometimes it is the selectedProfile Causing it to dismiss.

//Potential Bug of still appearing at the bottom is caused b

/*
 .overlay(alignment: .topTrailing) {
     Image(systemName: "xmark")
         .font(.body(17, .bold))
         .padding(5)
         .glassIfAvailable()
 }
 
 */
