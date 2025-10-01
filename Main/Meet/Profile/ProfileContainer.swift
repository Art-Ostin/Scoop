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
    
    private var cornerRadius: CGFloat {
        (selectedProfile != nil) ? max(0, min(30, profileOffset / 3)) : 30
    }
    
    
    
    @State var imageSize: CGFloat = 300
    
    init(vm: ProfileViewModel, preloadedImages: [UIImage]? = nil, meetVM: MeetViewModel? = nil, selectedProfile: Binding<ProfileModel?>) {
        _vm = State(initialValue: vm)
        self.preloadedImages = preloadedImages
        self.meetVM = meetVM
        self._selectedProfile = selectedProfile
    }
    
    var body: some View {
        
        ZStack(alignment: .topLeading) {
            
            VStack(spacing: isOverExtended ? top2Spacing() : topSpacing() ) {
                profileTitle
                    .padding(.top, isOverExtended ? top2Padding() : topPadding() )
                ProfileImageView(vm: $vm)
                    .overlay(alignment: .topLeading) { secondHeader}
            }
            
            ProfileDetailsView()
                .offset(y: detailsStartingOffset + detailsOffset + detailsDismissOffset + (detailsOpen ? detailsOpenYOffset : 0))
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
                .onTapGesture {detailsOpen.toggle() }
            
            detailsInfo
            
            InviteButton(vm: $vm)
                .offset(
                    x: (imageSize - inviteButtonSize - inviteButtonPadding + 8), //The plus 8 is the imagePadding
                    y: ((isOverExtended ? top2Padding() + top2Spacing() : topPadding() + topSpacing()) + imageSize - inviteButtonSize + 12)
                )
                .gesture(DragGesture())
            
            if vm.showInvitePopup { invitePopup }
        }
        .colorBackground(.background)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(radius: 10)
        .offset(y: profileOffset)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged {
                    let dragAmount = $0.translation.height
                    let dragDown = dragAmount > 0
                    let openDetails = !detailsOpen && profileOffset == 0

                    if dragDown {
                        profileOffset = dragAmount * 1.5
                        detailsDismissOffset = (-dragAmount * 1.5).clamped(to: -68...0)
                    } else if openDetails {
                        detailsOffset = $0.translation.height.clamped(to: detailsDragRange)
                    }
                }
                .onEnded {
                    let predicted = $0.predictedEndTranslation.height
                    let closeProfile = profileOffset > 180
                    let openDetails = detailsOffset < -50 || predicted < -50
                    let closeDetails = detailsOpen && detailsOffset > 60
                    
                    if closeProfile  || predicted > 180 {
                        selectedProfile = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { profileOffset = 0 }
                        return
                    }
                    
                    if (openDetails || closeDetails) && profileOffset == 0.00 { detailsOpen.toggle()} //Profile Offset must be 0, otherwise it opens up and down when trying to dismiss the profile
                    detailsDismissOffset = 0
                    detailsOffset = 0
                    profileOffset = 0
                }
        )
        .animation(.spring(duration: 0.2), value: animKey)
        .coordinateSpace(name: "profile")
        .onPreferenceChange(ScrollImageBottomValue.self) { y in
            if profileOffset != 0 {
                print("Tried to updated but didn't")
            } else {
                scrollImageBottomY  = y
            }
        }
        .onPreferenceChange(ImageWidthKey.self) {value in
            imageSize = value
            print("newValue = \(value)")
            
        }
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
        .opacity(isOverExtended ? top2Opacity() : topOpacity())
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
        return Double(detailsOpen ? t : (1 - t))
    }
    
    func topPadding() -> CGFloat {
        let initial: CGFloat = 84, dismiss: CGFloat = 16
        if profileOffset > 0 { return selectedProfile == nil ? dismiss : max(initial - profileOffset, dismiss) }
        return detailsOpen ? lerp(0, initial, t) : lerp(initial, 0, t)
    }
    
    func topSpacing() -> CGFloat {
        let maxS: CGFloat = 0, minS: CGFloat = 36
        return detailsOpen ? lerp(maxS, minS, t) : lerp(minS, maxS, t)
    }
    
    func top2Spacing() -> CGFloat {
        if detailsOpen {
            return 0
        } else {
            return 36
        }
    }
    
    func top2Padding() -> CGFloat {
        if detailsOpen {
            return 16
        } else {
            return 84
        }
    }
    
    func top2Opacity() -> Double {
        if detailsOpen {
            return 0
        } else {
            return 1
        }
    }
    var secondHeader: some View {
        HStack {
            Text(vm.profileModel.profile.name)
            Spacer()
            profileDismissButton(selectedProfile: $selectedProfile, color: .white)
        }
        .font(.body(24, .bold))
        .foregroundStyle(.white)
        .padding(.top, 36)
        .padding(.horizontal, 16)
        .opacity(title3Opacity())
    }
    
    func title3Opacity() -> Double {
        let beginTitleFade: CGFloat = -100
        if detailsOpen {
            return 1 - (abs(detailsOffset) / 100)
        } else if detailsOffset < beginTitleFade {
            return 0 + (abs(detailsOffset + 200) / 100)
        } else {
            return 0
        }
    }
    
    private var detailsInfo: some View {
        VStack(spacing: 12) {
            Text("ProfileOffset \(profileOffset)")
            
            Text("DetailsOffset \(detailsOffset)")
            
            Text("detailsOpen \(detailsOpen == true ? "true" : "false")")
            
            Text("IsOverExtended \(isOverExtended == true ? "true" : "false")")
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 250)
    }
}
