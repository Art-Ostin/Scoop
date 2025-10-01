import SwiftUI

struct ProfileView: View {

    @Environment(\.tabSelection) private var tabSelection
    @Environment(\.appDependencies) private var dep
    
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
    
    @State var imageSize: CGFloat = 300

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
                        .onChanged {value in
                            let range: ClosedRange<CGFloat> = detailsOpen ? (-60...220) : (-220...60)
                            detailsOffset = value.translation.height.clamped(to: range)
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
                .gesture( //Removes bug where if I dragged from Invite Button, broke code
                    DragGesture()
                )
            
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
                            
                            detailsDismissOffset = min(max(-dragAmount * 1.5, -68), 0)
                        }
                        else if !detailsOpen && profileOffset == 0 {
                            let range: ClosedRange<CGFloat> = detailsOpen ? (-60...220) : (-220...60)
                            detailsOffset = $0.translation.height.clamped(to: range)
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
            .animation(.spring(duration: 0.2), value: detailsOffset)
            .animation(.spring(duration: 0.2), value: detailsOpen)
            .animation(.spring(duration: 0.2), value: profileOffset)
            .animation(.spring(duration: 0.2), value: selectedProfile?.id)
            .onPreferenceChange(ScrollImageBottomValue.self) { y in
                if profileOffset != 0 {
                    print("Tried to updated but didn't")
                } else {
                    scrollImageBottomY  = y
                }
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
    
    func topOpacity() -> Double {
        if isOverExtended {
            return detailsOpen ? 0 : 1
        } else if detailsOpen {
            return (0  + (abs(detailsOffset) / abs(detailsOpenYOffset)))
        } else {
            return (1 - (abs(detailsOffset) / abs(detailsOpenYOffset)))
        }
    }
     
     func topPadding() -> CGFloat {
         let initial: CGFloat = 84
         let dismiss: CGFloat = 16
         let currentSpacing = min(max(abs(detailsOffset) / abs(detailsOpenYOffset), 0), 1)
         
         if isOverExtended {
             return detailsOpen ? dismiss : initial
         } else if profileOffset > 0 {
             return selectedProfile == nil ? dismiss : max(initial - profileOffset, dismiss)
         } else {
             return detailsOpen ? initial * currentSpacing : initial * (1 - currentSpacing)
         }
     }
    
    func topSpacing() -> CGFloat {
         let maxSpacing: CGFloat = 36
         let minSpacing: CGFloat = 0
         let currentSpacing: CGFloat = maxSpacing * abs(detailsOffset) / abs(detailsOpenYOffset)
        
        if isOverExtended {
            return detailsOpen ? 0 : 36
        } else if detailsOpen {
            return minSpacing + min(currentSpacing, maxSpacing)
        } else {
            return maxSpacing - max(currentSpacing, minSpacing)
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

//All the functionality for the details and profile View Modifiers



/*
 Geometry Reader needed: (1) Image is width of screen + its padding (2) Needed to swip
 GeometryReader { proxy in
     let imageSize: CGFloat = proxy.size.width - imagePadding
 */


/*
 VStack(spacing: 12) {
     Text("ProfileOffset \(profileOffset)")
     
     Text("DetailsOffset \(detailsOffset)")
 }
 .frame(maxWidth: .infinity, alignment: .center)
 .padding(.top, 250)
 */

/*
 .toolbar(vm.showInvitePopup ? .hidden : .visible, for: .tabBar)
 */

