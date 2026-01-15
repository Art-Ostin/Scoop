import SwiftUI
//Note: Geometry Reader needed to Keep the VStack from respecting the top safe Area

struct ProfileView: View {
    @Environment(\.tabSelection) private var tabSelection
    @Environment(\.dismiss) private var dismiss
    
    @GestureState var detailsOffset = CGFloat.zero
    @GestureState var profileOffset = CGFloat.zero
    
    @State private var vm: ProfileViewModel
    @State private var meetVM: MeetViewModel?
    
    @State private var showInvitePopup: Bool = false
    @State private var detailsOpen: Bool = false
    @State private var dragType: DragType? = nil
    @State private var isTopOfScroll = true
    @State private var scrollSelection: Int? = 0
    @State private var detailsOpenOffset: CGFloat = -284
    
    @Binding private var selectedProfile: ProfileModel?
        
    private var detailsDragRange: ClosedRange<CGFloat> {
        let limit = detailsOpenOffset - 80
        return detailsOpen ? (-85 ... -limit) : (limit ... 85)
    }
    
    let profileImages: [UIImage]
    
    init(vm: ProfileViewModel, meetVM: MeetViewModel? = nil, profileImages: [UIImage], selectedProfile: Binding<ProfileModel?>) {
        _vm = State(initialValue: vm)
        _meetVM = State(initialValue: meetVM)
        self.profileImages = profileImages
        _selectedProfile = selectedProfile
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 24) {
                ProfileTitle(p: vm.profileModel.profile, selectedProfile: $selectedProfile)
                    .offset(y: rangeUpdater(endValue: -108))
                    .opacity(titleOpacity())
                    .padding(.top, 36)
                
                ProfileImageView(vm: vm, showInvite: $showInvitePopup, detailsOffset: detailsOffset, importedImages: profileImages)
                    .offset(y: rangeUpdater(endValue: -108))
                    .simultaneousGesture(imageDetailsDrag)
                
                ProfileDetailsView(vm: vm, isTopOfScroll: $isTopOfScroll, scrollSelection: $scrollSelection, p: vm.profileModel.profile, event: vm.profileModel.event, detailsOpen: detailsOpen, detailsOffset: detailsOffset, showInvite: $showInvitePopup)
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
            .overlay(alignment: .topLeading) { overlayTitle }
        }
        .overlay {if showInvitePopup {invitePopup}}
        .offset(y: profileOffset)
    }
}

//Two Different views
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
    
    private var overlayTitle: some View {
        HStack {
            Text(vm.profileModel.profile.name)
            Spacer()
            ProfileDismissButton(color: .white, selectedProfile: $selectedProfile)
        }
        .font(.body(24, .bold))
        .contentShape(Rectangle())
        .zIndex(2)
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .opacity(overlayTitleOpacity())
    }
}

//Details Open or Closed  Offset
extension ProfileView {
    
    func detailsSectionOffset() -> CGFloat {
        if detailsOpen {
            return detailsOpenOffset + detailsOffset
        } else {
            return detailsOffset
        }
    }
    
    func overlayTitleOpacity() -> Double {
        //Fetch what value e.g. '84' is 1/3 and 2/3 of total detailsOffset
        let one_third = max(1, abs(detailsOpenOffset) / 3)
        
        //While closing (first third of the drag), fade from opaque to transparent.
        if detailsOpen {
            if abs(detailsOffset) < one_third {
                return 1 - min( detailsOffset/one_third, 1)
            } else {
                return 0
            }
        } else {
            if abs(detailsOffset) < one_third {
                return 0
            } else {
                return 0 + max((abs(detailsOffset) - one_third)/one_third, 0)
            }
        }
    }
    
    func titleOpacity() -> Double {
        return 1 - overlayTitleOpacity()
    }
    
    func rangeUpdater(startValue: CGFloat, endValue: CGFloat) -> CGFloat {
        let denom = max(abs(detailsOpenOffset), 0.0001)
        let t = min(abs(detailsOffset) / denom, 1)
        let delta = (endValue - startValue) * t
        var value = detailsOpen ? endValue : startValue
        if detailsOpen && detailsOffset > 0 {
            value -= delta
        } else if !detailsOpen && detailsOffset < 0 {
            value += delta
        }
        return value
    }
    
    func rangeUpdater(endValue: CGFloat) -> CGFloat {
        rangeUpdater(startValue: 0, endValue: endValue)
    }
}

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
                    selectedProfile = nil
                } else if dragType == .details {
                    detailsOpen.toggle()
                }
            }
    }
    
    private var detailsDrag: some Gesture {
        DragGesture(minimumDistance: 5)
            .updating($detailsOffset) { v, state, _ in
                if !isTopOfScroll && scrollSelection == 2 && detailsOpen { return}
                if isTopOfScroll && scrollSelection == 2 && detailsOpen && v.translation.height < 0 { return }
                if dragType == nil {dragType(v: v)}
                guard dragType != nil && dragType != .horizontal else { return }
                state = v.translation.height.clamped(to: detailsDragRange)
            }
            .onEnded {
                defer { dragType = nil }
                guard dragType != nil && dragType != .horizontal else { return }
                let predicted = $0.predictedEndTranslation.height
                if predicted < 50 /*&& profileOffset == 0*/ {
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
        self.dragType = (v.translation.height < 0 || detailsOpen) ? .details : .horizontal
    }
}


/*
 self._selectedProfile = selectedProfile
 */
/*
 .coordinateSpace(name: "profile")
 */



/*
 
 @GestureState var profileOffset = CGFloat.zero
 
 
 
 .updating($profileOffset) { value, state, _ in
 if dragType == nil { dragType(v: value) }
 guard dragType == .profile else { return }
 state = value.translation.height
 }
 */

/*
 if dragType == .profile {
 //                                    selectedProfile = nil
 dismiss()
 } else if dragType == .details {
 detailsOpen.toggle()
 }
 */

/*
 .simultaneousGesture(
 DragGesture(minimumDistance: 5)
 .updating($detailsOffset) { v, state, _ in
 guard v.translation.height < 0 else { return }
 if dragType == nil { dragType(v: v) }
 guard dragType == .details else { return }
 state = v.translation.height.clamped(to: detailsDragRange)
 }
 .onEnded { v in
 defer { dragType = nil }
 guard dragType == .details else { return }
 
 guard dragType != nil && dragType != .horizontal else { return }
 let predicted = abs(v.predictedEndTranslation.height)
 let distance = abs(v.translation.height)
 
 //Only update if user drags more than 75
 guard max(distance, predicted) > 75 else { return }
 }
 )
 
 */

/*
 //            .background(
 //                //Do not Change Critical! Fixed the scrolling down issue
 //                UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
 //                    .fill(Color.background)
 //                    .ignoresSafeArea()
 //                    .shadow(color: profileOffset.isZero ? Color.clear : .black.opacity(0.25), radius: 12, y: 6)
 //            )
 
 */

/*
 func InviteOffset() -> CGFloat {
 if detailsSectionTop < imageSectionBottom {
 print("")
 }
 let toggleDetailsYOffset = imageSectionBottom - detailsSectionTop
 
 
 print("Bottom: \(imageSectionBottom)")
 print("Top: \(detailsSectionTop)")
 
 return imageSectionBottom + rangeUpdater(endValue: toggleDetailsYOffset)
 }
 */

/*
 private var inviteButton: some View {
 InviteButton(vm: vm, showInvite: $showInvitePopup)
 .padding(.horizontal, 24)
 .offset(y: InviteOffset())
 //            .padding(.top, detailsSectionTop)
 .gesture(DragGesture())
 .onTapGesture { showInvitePopup = true}
 }
 */

/*
 .onPreferenceChange(ImageSectionBottom.self) {imageBottom in
 guard !measuredImage else {return}
 imageSectionBottom = imageBottom - 60
 //                Task { try? await Task.sleep(nanoseconds: 20000000) ; measuredImage = true}
 }
 .onPreferenceChange(TopOfDetailsView.self) { topOfDetails in
 guard !measuredDetails else {return}
 detailsSectionTop = (topOfDetails - 16) /*+ detailsOpenOffset*/ //get top when details Open
 //                print("Top of Details when Open: \(detailsSectionTop)")
 //                Task { try? await Task.sleep(nanoseconds: 20000000); measuredDetails = true}
 }
 */

/*
 @State var imageSectionBottom: CGFloat = 0
 @State var detailsSectionTop: CGFloat = 0
 */

/*
 @Binding var selectedProfile: ProfileModel?
 .animation(.easeInOut(duration: 0.2), value: selectedProfile)
 */

/*
 DragGesture(minimumDistance: 5)
     .updating($detailsOffset) { value, state, _ in
         guard !detailsOpen else { return }
         guard value.translation.height < 0 else { return }
         state = value.translation.height.clamped(to: detailsDragRange)
     }
     .onEnded { value in
         let openDetailsThreshold: CGFloat = -75
         guard value.translation.height < 0 else { return }
         let predicted = value.predictedEndTranslation.height
         if predicted < openDetailsThreshold {
             detailsOpen = true
         }
     }
 */

/*
 
 self.dragType = detailsOpen ? dy.
 
 self.dragType = detailsOpen ? ( dy < 0 ? )
 
 
 
 
 
 //If it passes conditions updates 'drag type'
 self.dragType = (v.translation.height < 0 || detailsOpen) ? .details : .profile
 */

/*
 DragGesture(minimumDistance: 5) //Critical its 20
     .updating($detailsOffset) { v, state, _ in
         if dragType == nil { dragType(v: v) }
         guard dragType == .details else { return }
         state = v.translation.height.clamped(to: detailsDragRange)
     }
 
 .onEnded { v in
     defer { dragType = nil }
     guard dragType == .details else { return }
     let predicted = abs(v.predictedEndTranslation.height)
     let distance = abs(v.translation.height)
     //Only update if user drags more than 75
     if max(distance, predicted) > 75 { detailsOpen.toggle()}
 }


 */
