import SwiftUI

//    @State var blockTabView: Bool = false
//     @State var inviteYOffset: CGFloat = -96
//     @GestureState var detailsDismissOffset: CGFloat = 0
//     @State var detailsPad: CGFloat = 0
/*
 private var cornerRadius: CGFloat {
     (selectedProfile != nil) ? max(0, min(30, profileOffset / 3)) : 30
 }
 */

struct ProfileView: View {
    
    @Environment(\.tabSelection) private var tabSelection
    
    @State private var vm: ProfileViewModel
    @State private var meetVM: MeetViewModel?
    
    let titlePadding: CGFloat = 36
    var imagePadding: CGFloat {titlePadding + 24}
    var detailsPadding: CGFloat {imageSectionBottom}
    var inviteButtonPadding: CGFloat {imageSectionBottom - 175}
    
    @Binding var selectedProfile: ProfileModel?
    @State var showInvitePopup: Bool = false
    @State var detailsOpen: Bool = false

    @GestureState var detailsOffset = CGFloat.zero
    @GestureState var profileOffset = CGFloat.zero
    
    @State var imageSectionBottom: CGFloat = 0
    @State var detailsOpenOffset: CGFloat = -150 //Turn this into a PreferenceKey measuring openOffset based of how much needed
    @State var topSafeArea: CGFloat = 0
    
    @State private var dragAxis: Axis? = nil
    let preloadedImages: [UIImage]?
    let toggleDetailsThreshold: CGFloat = -50
    private var detailsDragRange: ClosedRange<CGFloat> {
        detailsOpen ? (-85...220) : (-220...85)
    }
    
    init(vm: ProfileViewModel, preloadedImages: [UIImage]? = nil, meetVM: MeetViewModel? = nil, selectedProfile: Binding<ProfileModel?>) {
        _vm = State(initialValue: vm)
        self.preloadedImages = preloadedImages
        _meetVM = State(initialValue: meetVM)
        self._selectedProfile = selectedProfile
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            
            ProfileTitle(p: vm.profileModel.profile, selectedProfile: $selectedProfile)
                .padding(.top, titlePadding)
                .offset(y: titleOffset())
                .opacity(titleOpacity())
            
            ProfileImageView(vm: vm)
                .padding(.top, imagePadding)
                .offset(y: imageOffset())
                .overlay(alignment: .topLeading) { overlayTitle }
                .simultaneousGesture(
                    DragGesture()
                        .updating($profileOffset) { value, state, _ in
                            guard dragType(v: value) == .vertical, detailsOpen == false else {return}
                            state = value.translation.height
                        }
                        .updating($detailsOffset) { value, state, _ in
                            guard dragType(v: value) == .vertical else {return}
                            if !detailsOpen && value.translation.height < 0 {
                                state = value.translation.height.clamped(to: detailsDragRange)
                            }
                        }
                    
                        .onEnded { v in
                            defer { dragAxis = nil }
                            guard dragAxis == .vertical else { return }
                            let predicted = v.predictedEndTranslation.height
                            let distance = v.translation.height
                            let dismissThreshold: CGFloat = 50
                            
                            let openDetails = predicted < toggleDetailsThreshold && !detailsOpen && profileOffset == 0
                            
                            if max(distance, predicted) > dismissThreshold {
                                selectedProfile = nil
                            } else if openDetails{
                                detailsOpen = true
                            }
                        }
                )
            
            ProfileDetailsView(p: vm.profileModel.profile, event: vm.profileModel.event)
                .padding(.top, detailsPadding)
                .offset(y: detailsSectionOffset())
                .onTapGesture {detailsOpen.toggle()}
                .simultaneousGesture(
                    DragGesture()
                        .updating($detailsOffset) { v, state, _ in
                            guard dragType(v: v) == .vertical else { return }
                            state = v.translation.height.clamped(to: detailsDragRange)
                        }
                        .onEnded {
                            defer { dragAxis = nil }
                            guard dragAxis == .vertical else { return }
                            let predicted = $0.predictedEndTranslation.height
                            
                            if predicted < toggleDetailsThreshold && profileOffset == 0 {
                                detailsOpen = true
                            } else if detailsOpen && predicted > 60 {
                                detailsOpen = false
                            }
                        }
                )
            
            if showInvitePopup {
                invitePopup
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .offset(y: profileOffset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).background(Color.background)
        .clipShape(RoundedRectangle(cornerRadius: profileOffset == 0 ? 32 : 0))
        .shadow(radius: 10)
        .contentShape(Rectangle())
        .animation(.spring(duration: 0.2), value: detailsOpen)
        .animation(.easeOut(duration: 0.25), value: profileOffset)
        .animation(.easeInOut(duration: 0.2), value: detailsOffset)
        .coordinateSpace(name: "profile")
        .onPreferenceChange(ImageSectionBottom.self) {imageBottom in
            imageSectionBottom = imageBottom + 24 //padding
        }
    }
}

//Two Different views
extension ProfileView {
    @ViewBuilder
    private var invitePopup: some View {
        CustomScreenCover {showInvitePopup = false }

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
                SelectTimeAndPlace(profile: vm.profileModel, onDismiss: { showInvitePopup = false }) { event in
                    try? await meetVM.sendInvite(event: event, profileModel: vm.profileModel)
                    selectedProfile = nil
                }
            }
        }
    }
    
    private var overlayTitle: some View {
        HStack {
            Text(vm.profileModel.profile.name)
            Spacer()
            profileDismissButton(selectedProfile: $selectedProfile, color: .white)
        }
        .font(.body(24, .bold))
        .foregroundStyle(.white)
        .padding(.top, 32)
        .padding(.horizontal, 16)
        .opacity(overlayTitleOpacity())
    }
    
    private func dragType(v: DragGesture.Value) -> Axis? {
        if let dragAxis { return dragAxis }
        let dy = abs(v.translation.height)
        let dx = abs(v.translation.width)
        let dragThresh: CGFloat = 5
        if max(dx, dy) >= dragThresh {
            dragAxis = (dy > dx) ? .vertical : .horizontal
            return dragAxis
        }
        return nil
    }
}

//Details Open or Closed  Offset
extension ProfileView {
    
    func titleOffset() -> CGFloat {
        if detailsOpen && detailsOffset < 0 && abs(detailsOffset) < titlePadding {
            return -titlePadding + abs(detailsOffset)
        } else if detailsOpen {
            return -titlePadding
        } else {
            return 0
        }
    }
    
    func imageOffset() -> CGFloat {
        if detailsOpen {
            return -imagePadding + detailsOffset
        }
        if detailsOpen {
            return -imagePadding
        } else {
            if detailsOffset <= imagePadding {
                return -(imagePadding - detailsOffset)
            }
            return 0
        }
    }
    
    func detailsSectionOffset() -> CGFloat {
        if detailsOpen {
            print("Details is Open")
            return detailsOpenOffset + detailsOffset
        } else {
            return detailsOffset
        }
    }
    
    func overlayTitleOpacity() -> Double {
        let one_third = max(1, abs(detailsOpenOffset) / 3)
        let two_third = one_third * 2
        
        if detailsOpen {
            if abs(detailsOffset) < one_third {
                return 1 - min( detailsOffset/one_third, 1)
            } else {
                return 0
            }
        } else {
            if abs(detailsOffset) < two_third {
                return 0
            } else {
                return 0 + max((abs(detailsOffset) - two_third) / one_third, 0)
            }
        }
    }
    
    func titleOpacity() -> Double {
        return 1 - overlayTitleOpacity()
    }
}


/*
 InviteButton(vm: vm, showInvite: $showInvitePopup)
     .padding(.top, inviteButtonPadding)
     .frame(maxWidth: .infinity, alignment: .bottomTrailing)
     .padding(.horizontal, 24)
     .gesture(DragGesture())

 */




/*
 InviteButton(vm: vm, showInvite: $showInvitePopup)
     .padding(.top, inviteButtonPadding)
     .frame(maxWidth: .infinity, alignment: .bottomTrailing)
     .gesture(DragGesture())
 */



/*
 var isOverExtended: Bool {
     (detailsOpen && (detailsOffset < 0 || detailsOffset == 0)) || (!detailsOpen && detailsOffset > 0)
 }
 */



/*
 
 @inline(__always) private func lerp(_ start: CGFloat,_ end: CGFloat,_ progress: CGFloat) -> CGFloat { start + (end - start) * progress }
 
 private var t: CGFloat {
     let denom = max(1, abs(detailsOpenOffset))
     return min(1, max(0, abs(detailsOffset) / denom))
 }
 
 */


/*
 
 func detailsPadding() -> CGFloat {
     let initial: CGFloat = 0.97, opened: CGFloat = 1
     return detailsOpen ? lerp(opened, initial, t) : lerp(initial, opened, t)
 }
 
 func topOpacity() -> Double {
     return Double(detailsOpen ? t : (1 - t))
 }
 
 func topPadding() -> CGFloat {
     let initial: CGFloat = 84, dismiss: CGFloat = 16
     
     if selectedProfile == nil {
         return 16
     } else if profileOffset > 0 {
         return max(initial - profileOffset, dismiss)
     } else {
         return detailsOpen ? lerp(0, initial, t) : lerp(initial, 0, t)
     }
     
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
 */




/*
 */

/*
 .onChange(of: detailsPadding()) { _, newValue in
     detailsPad = newValue
 }
 
 
 func topSpacing() -> CGFloat {
     let maxS: CGFloat = 0, minS: CGFloat = 36
     return detailsOpen ? lerp(maxS, minS, t) : lerp(minS, maxS, t)
 }
 */




/*
    .offset(y: (detailsOpen ? detailsOpenOffset : detailsClosedOffset) + detailsOffset)
    .offset(y: 2000)
 */

/*
 func inviteOffset() -> CGFloat {
     let initial: CGFloat = 0
     let opened:  CGFloat = inviteYOffset
     if detailsOpen {
         let p = (t / 0.25).clamped(to: 0...1)
         return lerp(opened, initial, p)
     } else {
         let p = ((t - 0.75) / 0.25).clamped(to: 0...1)
         return lerp(initial, opened, p)
     }
 }
 */



/*
 
 .padding(.top, isOverExtended ? (detailsOpen ? -8 : 84) : topPadding())

 
 InviteButton(vm: $vm)
 .offset(
 x: (imageSize - inviteButtonSize - inviteButtonPadding + 8), //The plus 8 is the imagePadding
 y: ((isOverExtended ? top2Padding() + top2Spacing() : topPadding() + topSpacing()) + imageSize - inviteButtonSize + 12)
 )
 .offset(y: isOverExtended ? (detailsOpen ? inviteYOffset : 0) : inviteOffset())
 .gesture(DragGesture())
 if vm.showInvitePopup {
 invitePopup
 .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
 }
 }
 */

/*
 .updating ($detailsDismissOffset) { value, state, _ in
 guard isVerticalDrag(v: value), value.translation.height > 0, detailsOffset == 0 else { return }
 profileOpened = true
 state = (-64 - value.translation.height).clamped(to: -68...0)
 }
 
 
 
 guard DragType(v: value) == .vertical else { return}
 state = value.translation.height
 
 
 
 
 
 guard isVerticalDrag(v: v), v.translation.height > 0, detailsOffset == 0 else { return }
 print("Vertical Drag Confirmed")
 state = v.translation.height + 64
 
 
 
 .onEnded { v in
 defer { dragAxis = nil }
 guard dragAxis == .vertical else { return }
 blockTabView = false
 let predicted = v.predictedEndTranslation.height
 let openDetails = predicted < -50 && !detailsOpen && profileOffset == 0 && !profileOpened
 
 let distance = v.translation.height
 let dismissThreshold: CGFloat = 50
 if distance > dismissThreshold || predicted > dismissThreshold  {
 selectedProfile = nil
 } else if openDetails {
 detailsOpen = true
 }
 
 DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
 profileOpened = false
 }
 },
 including: .gesture
 )
 
 
 //                .transition(AnyTransition.move(edge: Edge.bottom))
 
 */

