import SwiftUI

/*
 Note: Geometry Reader needed to Keep the VStack from respecting hte top safe Area
 */

struct ProfileView: View {
    
    @Environment(\.tabSelection) private var tabSelection
    
    @State private var vm: ProfileViewModel
    @State private var meetVM: MeetViewModel?
    
    var inviteButtonPadding: CGFloat { max(imageSectionBottom - 175, 0) }
    
    @Binding var selectedProfile: ProfileModel?
    @State var showInvitePopup: Bool = false
    @State var detailsOpen: Bool = false
    
    @GestureState var detailsOffset = CGFloat.zero
    @GestureState var profileOffset = CGFloat.zero
    
    @State var imageSectionBottom: CGFloat = 0
    @State var detailsSectionTop: CGFloat = 0
    @State var detailsOpenOffset: CGFloat = -292 //Turn this into a PreferenceKey measuring openOffset based of how much needed
    
    @State private var dragType: DragType? = nil
    
    let preloadedImages: [UIImage]?
    private var detailsDragRange: ClosedRange<CGFloat> {
        let limit = detailsOpenOffset - 80
        return detailsOpen ? (-85 ... -limit) : (limit ... 85)
    }
    
    init(vm: ProfileViewModel, preloadedImages: [UIImage]? = nil, meetVM: MeetViewModel? = nil, selectedProfile: Binding<ProfileModel?>) {
        _vm = State(initialValue: vm)
        self.preloadedImages = preloadedImages
        _meetVM = State(initialValue: meetVM)
        self._selectedProfile = selectedProfile
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 24) {
                ProfileTitle(p: vm.profileModel.profile, selectedProfile: $selectedProfile)
                    .offset(y: rangeUpdater(endValue: -108))
                    .opacity(titleOpacity())
                    .padding(.top, 36)
                
                ProfileImageView(vm: vm, showInvite: $showInvitePopup)
                    .offset(y: rangeUpdater(endValue: -108))
                    .simultaneousGesture(
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
                    )
                
                ProfileDetailsView(vm: vm, showInvite: $showInvitePopup, p: vm.profileModel.profile, event: vm.profileModel.event)
                    .offset(y: detailsSectionOffset())
                    .onTapGesture {detailsOpen.toggle()}
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 5)
                            .updating($detailsOffset) { v, state, _ in
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
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.background)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, topTrailingRadius: 0))
            .shadow(color: .black.opacity(profileShadowOpacity),radius: profileShadowRadius,y: profileShadowYOffset)
            .animation(.spring(duration: 0.2), value: detailsOpen)
            .animation(.easeOut(duration: 0.25), value: profileOffset)
            .animation(.easeInOut(duration: 0.2), value: detailsOffset)
            .overlay(alignment: .topLeading) { overlayTitle }
            .onPreferenceChange(ImageSectionBottom.self) {imageBottom in
                if imageSectionBottom == 0 {
                    imageSectionBottom = imageBottom - 60
                }
            }
            .onPreferenceChange(TopOfDetailsView.self) { topOfDetails in
                if detailsSectionTop == 0 {
                    detailsSectionTop = topOfDetails
                }
            }
            .coordinateSpace(name: "profile")
        }
        .offset(y: profileOffset)
        .overlay {invitePopup}
    }
}

/*
 .clipShape(RoundedRectangle(cornerRadius: 0))
 .shadow(radius: 10)
 */

//Two Different views
extension ProfileView {
    
    @ViewBuilder
    private var invitePopup: some View {
        if showInvitePopup {
            if let event = vm.profileModel.event {
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
                    selectedProfile = nil
                }
            }
        }
    }
    
    private var inviteButton: some View {
        InviteButton(vm: vm, showInvite: $showInvitePopup)
            .frame(maxWidth: .infinity, alignment: .topTrailing)
            .padding(.horizontal, 24)
            .padding(.top, imageSectionBottom)
            .gesture(DragGesture())
            .onTapGesture { showInvitePopup = true}
    }
    
    private var overlayTitle: some View {
        HStack {
            Text(vm.profileModel.profile.name)
            Spacer()
            profileDismissButton(selectedProfile: $selectedProfile, color: .white)
        }
        .font(.body(24, .bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .opacity(overlayTitleOpacity())
    }
    
    private func dragType(v: DragGesture.Value) {
        //If there is already a dragType don't reassign it (here), get y and x drag
        if self.dragType != nil  {return }
        let dy = abs(v.translation.height)
        let dx = abs(v.translation.width)
        print("function called")
        
        //Ensures user drags at least 5 points, and its a vertical drag
        guard dy > dx else { dragType = .horizontal; return}
        
        //If it passes conditions updates 'drag type'
        self.dragType = (v.translation.height < 0 || detailsOpen) ? .details : .profile
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
    
    func rangeUpdater(endValue: CGFloat) -> CGFloat {
        //Get % details has moved and thus, how much to offset the specific view
        let percent = min(abs(detailsOffset) / abs(detailsOpenOffset), 1)
        let move_amount = abs(endValue) * percent
        
        // Start from the “resting” position: fully open uses endValue; closed uses 0.
        var offset: CGFloat = detailsOpen ? endValue : 0
        
        // Apply the drag-driven adjustment but only if dragging in correct direction
        if detailsOpen && detailsOffset > 0 {
            offset += move_amount
        } else if !detailsOpen && detailsOffset < 0 {
            offset -= move_amount
        }
        return offset
    }
}
//For the Dismisall of container
extension ProfileView {
    private var dismissalProgress: CGFloat {
        let maxOffset: CGFloat = 60
        return min(max(profileOffset, 0), maxOffset) / maxOffset
    }
    private var profileCornerRadius: CGFloat { dismissalProgress * 32 }
    private var profileShadowOpacity: Double { dismissalProgress == 0 ? 0 : Double(0.25 * dismissalProgress) }
    private var profileShadowRadius: CGFloat { dismissalProgress * 12 }
    private var profileShadowYOffset: CGFloat { dismissalProgress * 6 }
}

enum DragType {
    case details, profile, horizontal
}

/*
 /* Use when dismissing stage
  .clipShape(RoundedRectangle(cornerRadius: profileOffset == 0 ? 32 : 0))
  */
 */
