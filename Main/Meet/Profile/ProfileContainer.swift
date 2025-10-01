import SwiftUI

struct ProfileView: View {
    
    @Environment(\.tabSelection) private var tabSelection
    
    @State private var vm: ProfileViewModel
    @State private var meetVM: MeetViewModel?
    
    @Binding var selectedProfile: ProfileModel?
    
    let preloadedImages: [UIImage]?
    
    let detailsTopPadding: CGFloat = 36
    let inviteButtonPadding: CGFloat = 12
    let inviteButtonSize: CGFloat = 50
    let toggleDetailsThresh: CGFloat = -50
    
    var detailsStartingOffset: CGFloat {scrollImageBottomY + detailsTopPadding}
    let detailsOpenYOffset: CGFloat = -170
    @State var detailsOffset: CGFloat = 0
    @State var detailsOpen: Bool = false
    
    @State var scrollImageBottomY: CGFloat = 0
    
    @State var profileOffset: CGFloat = 0
    @State private var detailsDismissOffset: CGFloat = 0
    
    @State var imageSize: CGFloat = 10
    
    init(vm: ProfileViewModel, preloadedImages: [UIImage]? = nil, meetVM: MeetViewModel? = nil, selectedProfile: Binding<ProfileModel?>) {
        _vm = State(initialValue: vm)
        self.preloadedImages = preloadedImages
        self.meetVM = meetVM
        self._selectedProfile = selectedProfile
    }
    
    var body: some View {
        
        ZStack(alignment: .topLeading) {
            
            VStack(spacing: topSpacing()) {
                profileTitle
                ProfileImageView(vm: $vm)
                    .overlay(alignment: .topLeading) { secondHeader}
            }
            
            ProfileDetailsView()
                .offset(y: detailsStartingOffset + detailsOffset + detailsDismissOffset + (detailsOpen ? detailsOpenYOffset : 0))
                .onTapGesture {detailsOpen.toggle() }
                .gesture (
                    DragGesture()
                        .onChanged {
                            detailsOffset = $0.translation.height.clamped(to: detailsDragRange)
                        }
                        .onEnded {
                            let predicted = $0.predictedEndTranslation.height
                            if detailsOffset < -40 || predicted <  toggleDetailsThresh{
                                detailsOpen = true
                            } else if detailsOpen && detailsOffset > 60 {
                                detailsOpen = false
                            }
                            detailsOffset = 0
                        }
                )
            
            InviteButton(vm: $vm)
                .offset (
                    x: imageSize - inviteButtonSize - inviteButtonPadding,
                    y: (topPadding() + topSpacing() + imageSize - inviteButtonSize)
                )
                .gesture(DragGesture())
            
            if vm.showInvitePopup { invitePopup }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
        .clipShape(RoundedRectangle(cornerRadius: (selectedProfile != nil) ? max(0, min(30, profileOffset / 3)) : 30, style: .continuous))
        .shadow(radius: 10)
        .contentShape(Rectangle())
        .coordinateSpace(name: "profile")
        .gesture(
            DragGesture()
                .onChanged {
                    
                    let dragAmount = $0.translation.height
                    let dragDown = dragAmount > 0
                    
                    
                    if dragDown {
                        profileOffset = dragAmount * 1.5
                        
                        detailsDismissOffset = (-dragAmount * 1.5).clamped(to: -68...0)

                    }
                    else if !detailsOpen && profileOffset == 0 {
                        detailsOffset = $0.translation.height.clamped(to: detailsDragRange)
                    }
                }
            
                .onEnded {
                    let predicted = $0.predictedEndTranslation.height
                    let closeProfile = profileOffset > 180
                    
                    let openDetails = detailsOffset < -50 || predicted < -50
                    let closeDetails = detailsOpen && detailsOffset > 60
                    
                    if closeProfile  || predicted > 180 {
                        withAnimation(.easeInOut(duration: 0.25)) { selectedProfile = nil }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { profileOffset = 0 }
                        return
                    }
                    
                    if (openDetails || closeDetails) && profileOffset == 0.00 { detailsOpen.toggle()} //Profile Offset must be 0, otherwise it opens up and down when trying to dismiss the profile
                    detailsDismissOffset = 0
                    detailsOffset = 0
                    profileOffset = 0
                }
        )
        .offset(y: profileOffset)
        .animation(.spring(duration: 0.2), value: animKey)
        .onPreferenceChange(ScrollImageBottomValue.self) { y in
            if profileOffset != 0 {
                print("Tried to updated but didn't")
            } else {
                scrollImageBottomY  = y
            }
        }
        .onPreferenceChange(ImageWidthKey.self) { imageSize = $0 }
    }
    
    private struct AnimKey: Equatable {
      var detailsOffset: CGFloat
      var detailsOpen: Bool
      var profileOffset: CGFloat
      var selectedID: String?
    }
    private var animKey: AnimKey {
      .init(detailsOffset: detailsOffset,
            detailsOpen: detailsOpen,
            profileOffset: profileOffset,
            selectedID: selectedProfile?.id)
    }
    
    private var detailsDragRange: ClosedRange<CGFloat> {
      detailsOpen ? (-60...220) : (-220...60)
    }

}

// All the functionality for title and Popup
extension ProfileView {
    private var profileTitle: some View {
        HStack {
            let p = vm.profileModel.profile
            Text(p.name)
            ForEach (p.nationality, id: \.self) {flag in Text(flag)}
            Spacer()
            profileDismissButton(selectedProfile: $selectedProfile, color: Color.gray.opacity(0.6))
        }
        .font(.body(24, .bold))
        .padding(.horizontal)
        .opacity(topOpacity())
        .padding(.top, topPadding())
    }
    
    @ViewBuilder
    private var invitePopup: some View {
        InviteBackground()
            .onTapGesture { vm.showInvitePopup = false }
        if let event = vm.profileModel.event {
            AcceptInvitePopup(profileModel: vm.profileModel) {
                if let meetVM {
                    @Bindable var meetVM = meetVM
                    Task { try? await meetVM.acceptInvite(profileModel: vm.profileModel, userEvent: event) }
                    tabSelection.wrappedValue = 1
                }
            }
        } else {
            if let meetVM {
                SelectTimeAndPlace(vm: TimeAndPlaceViewModel(profile: vm.profileModel) { event in
                    @Bindable var meetVM = meetVM
                    Task { try? await meetVM.sendInvite(event: event, profileModel: vm.profileModel) }
                    selectedProfile = nil
                })
            }
        }
    }
}

// All the functionality for animation when scrolling up and down
extension ProfileView {
    
    var isOverExtended: Bool {
        (detailsOpen && detailsOffset < 0) || (!detailsOpen && detailsOffset > 0)
    }
    
    private var t: CGFloat {
        let denom = max(1, abs(detailsOpenYOffset))
        return min(1, max(0, abs(detailsOffset) / denom))
    }
    @inline(__always) private func lerp(_ a: CGFloat,_ b: CGFloat,_ t: CGFloat) -> CGFloat { a + (b - a) * t }
    
    func topOpacity() -> Double {
        if isOverExtended { return detailsOpen ? 0 : 1 }
        return Double(detailsOpen ? t : (1 - t))
    }
    
    func topPadding() -> CGFloat {
        let initial: CGFloat = 84, dismiss: CGFloat = 16
        if isOverExtended { return detailsOpen ? dismiss : initial }
        if profileOffset > 0 { return selectedProfile == nil ? dismiss : max(initial - profileOffset, dismiss) }
        return detailsOpen ? lerp(0, initial, t) : lerp(initial, 0, t)
    }
    
    func topSpacing() -> CGFloat {
        let minS: CGFloat = 0, maxS: CGFloat = 36
        if isOverExtended { return detailsOpen ? minS : maxS }
        return detailsOpen ? lerp(maxS, minS, t) : lerp(minS, maxS, t)
    }
    
    
    var secondHeader: some View {
        HStack {
            Text(vm.profileModel.profile.name)
            Spacer()
            profileDismissButton(selectedProfile: $selectedProfile, color: .white)
        }
        .font(.body(24, .bold))
        .foregroundStyle(.white)
        .padding()
        .opacity(title2Opacity())
    }
    
    
    func title2Opacity() -> Double {
        let beginTitleFade: CGFloat = -100
        if detailsOpen {
            return 1 - (abs(detailsOffset) / 100)
        } else if detailsOffset < beginTitleFade {
            return 0 + (abs(detailsOffset + 200) / 100)
        } else {
            return 0
        }
    }
}
