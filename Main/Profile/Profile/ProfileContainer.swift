import SwiftUI
//Note: Geometry Reader needed to Keep the VStack from respecting the top safe Area

struct ProfileView: View {
    @Environment(\.tabSelection) private var tabSelection

    @GestureState var detailsOffset = CGFloat.zero
    @GestureState var profileOffset = CGFloat.zero
    @State private var dismissOffset: CGFloat? = nil
    
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
    @Binding var declinedTransition: Bool
    
    private var detailsDragRange: ClosedRange<CGFloat> {
        let limit = detailsOpenOffset - 80
        return detailsOpen ? (-85 ... -limit) : (limit ... 85)
    }
    
    let profileImages: [UIImage]
    init(vm: ProfileViewModel, meetVM: MeetViewModel? = nil, profileImages: [UIImage], selectedProfile: Binding<ProfileModel?>, declinedTransition: Binding<Bool>) {
        _vm = State(initialValue: vm)
        self.meetVM = meetVM
        self.profileImages = profileImages
        _selectedProfile = selectedProfile
        _declinedTransition = declinedTransition
    }
    
    var body: some View {
            GeometryReader { geo in
                ZoomContainer {
                    if !hideProfileScreen {
                            VStack(spacing: 24) {
                                ProfileTitle(p: vm.profileModel.profile, selectedProfile: $selectedProfile) { selectedProfile = nil}
                                    .offset(y: rangeUpdater(endValue: -108))
                                    .opacity(1 - overlayTitleOpacity)
                                    .padding(.top, 36)
                                
                                ProfileImageView(vm: vm, showInvite: $showInvitePopup, detailsOffset: detailsOffset, importedImages: profileImages)
                                    .offset(y: rangeUpdater(endValue: -100))
                                    .simultaneousGesture(imageDetailsDrag)
                                    .onTapGesture { if detailsOpen { detailsOpen.toggle()}}
                                
                                ProfileDetailsView(vm: vm, isTopOfScroll: $isTopOfScroll, showInvite: $showInvitePopup, detailsOpen: detailsOpen, detailsOffset: detailsOffset, p: vm.profileModel.profile) {onDecline()}
                                    .scaleEffect(rangeUpdater(startValue: 0.97, endValue: 1.0), anchor: .top)
                                    .offset(y: detailsSectionOffset())
                                    .onTapGesture {detailsOpen.toggle()}
                                    .simultaneousGesture(detailsDrag)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(
                                //Do not Change Critical! Fixed the scrolling down issue
                                UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                                    .fill(Color.background)
                                    .ignoresSafeArea()
                                    .shadow(color: profileOffset.isZero ? Color.clear : .black.opacity(0.25), radius: 12, y: 6)
                            )
                            .animation(.spring(duration: 0.2), value: detailsOpen)
                            .animation(.easeInOut(duration: 0.2), value: detailsOffset)
                            .animation(.easeOut(duration: 0.25), value: profileOffset)
                            .animation(.snappy(duration: 1), value: selectedProfile)
                            .overlay(alignment: .topLeading) { overlayTitle() { selectedProfile = nil} }
                        }
                    }
                }
            .overlay {if showInvitePopup {invitePopup}}
            .overlay { if showDeclineScreen { declineScreen} }
            .offset(y: activeProfileOffset)
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
    
    private func overlayTitle(onDismiss: @escaping () -> Void) -> some View {
        HStack {
            Text(vm.profileModel.profile.name)
            Spacer()
            ProfileDismissButton(color: .white, selectedProfile: $selectedProfile, onDismiss: onDismiss)
                .padding(6)
                .glassIfAvailable(Circle())
        }
        .font(.body(24, .bold))
        .contentShape(Rectangle())
        .zIndex(2)
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
    private func onDecline() {
        declinedTransition = true
        showDeclineScreen = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {hideProfileScreen = true}
        Task {
            //       try await meetVM?.declineProfile(profileModel: pModel)
            try await Task.sleep(nanoseconds: 750_000_000)
            await MainActor.run {withAnimation(.easeInOut(duration: 5)) {selectedProfile = nil}}
        }
    }
}



/*
 init(vm: ProfileViewModel, meetVM: MeetViewModel? = nil, profileImages: [UIImage], selectedProfile: Binding<ProfileModel?>, declinedTransition: Binding<Bool>) {        _vm = State(initialValue: vm)
     _meetVM = State(initialValue: meetVM)
     self.profileImages = profileImages
     _selectedProfile = selectedProfile
     _declinedTransition = declinedTransition
 }
 */
