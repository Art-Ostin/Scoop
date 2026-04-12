import SwiftUI


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
    @State var detailsOpenOffset: CGFloat = -150 //Turn this into a PreferenceKey measuring openOffset based of how much needed
    
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
        ZStack {
            VStack(spacing: 24) {
                ProfileTitle(p: vm.profileModel.profile, selectedProfile: $selectedProfile)
                    .offset(y: titleOffset())
                    .opacity(titleOpacity())
                    .padding(.top, 36)
                
                ProfileImageView(vm: vm)
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
                                
                                if max(distance, predicted) > dismissThreshold && !detailsOpen {
                                    selectedProfile = nil
                                } else if openDetails {
                                    detailsOpen = true
                                }
                            }
                    )
                
                ProfileDetailsView(p: vm.profileModel.profile, event: vm.profileModel.event)
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
            }
            
            InviteButton(vm: vm, showInvite: $showInvitePopup)
                .frame(maxWidth: .infinity, alignment: .bottomTrailing)
                .gesture(DragGesture())
            
            if showInvitePopup {
                invitePopup
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .offset(y: profileOffset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.background)
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
        let titlePadding: CGFloat = 12
        
        if detailsOpen && detailsOffset < 0 && abs(detailsOffset) < titlePadding {
            return -titlePadding + abs(detailsOffset)
        } else if detailsOpen {
            return -titlePadding
        } else {
            return 0
        }
    }
    
    func imageOffset() -> CGFloat {
        return 0
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
