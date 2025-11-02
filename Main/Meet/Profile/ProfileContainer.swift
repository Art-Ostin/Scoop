import SwiftUI

struct ProfileView: View {
    
    @Environment(\.tabSelection) private var tabSelection
    
    @State private var vm: ProfileViewModel
    @State private var meetVM: MeetViewModel?
    
    @Binding var selectedProfile: ProfileModel?
    
    @State private var scrollSelection: Int? = nil
    
    let preloadedImages: [UIImage]?
    
    let detailsTopPadding: CGFloat = 24
    let inviteButtonPadding: CGFloat = 12
    let inviteButtonSize: CGFloat = 50
    let toggleDetailsThresh: CGFloat = -50
    
    var detailsStartingOffset: CGFloat {scrollImageBottomY + detailsTopPadding}
    let detailsOpenYOffset: CGFloat = -240
    
    @GestureState var detailsOffset = CGFloat.zero
    @GestureState var profileOffset = CGFloat.zero
    @State var profileOpened = false
    @State var detailsOpen: Bool = false
    @State var scrollImageBottomY: CGFloat = 0
    private var cornerRadius: CGFloat {
        (selectedProfile != nil) ? max(0, min(30, profileOffset / 3)) : 30
    }
    @GestureState var detailsDismissOffset: CGFloat = 0
    @State private var dragAxis: Axis? = nil
    @State var blockTabView: Bool = false
    @State var detailsPad: CGFloat = 0
    @State var inviteYOffset: CGFloat = -108
    @State var imageSize: CGFloat = 300
        
    init(vm: ProfileViewModel, preloadedImages: [UIImage]? = nil, meetVM: MeetViewModel? = nil, selectedProfile: Binding<ProfileModel?>) {
        _vm = State(initialValue: vm)
        self.preloadedImages = preloadedImages
        self.meetVM = meetVM
        self._selectedProfile = selectedProfile
    }
    
    var body: some View {
        
        GeometryReader { proxy in
            let screenWidth = proxy.size.width
            
            ZStack(alignment: .topLeading) {
                VStack(spacing: isOverExtended ? (detailsOpen ? 0 : 36) : topSpacing() ) {
                    profileTitle
                        .padding(.top, isOverExtended ? (detailsOpen ? -8 : 84) : topPadding())
                    ProfileImageView(vm: $vm, screenWidth: screenWidth)
                        .overlay(alignment: .topLeading) { secondHeader}
                }
                .simultaneousGesture (
                    DragGesture()
                        .updating ($detailsDismissOffset) { v, state, transaction in
                            guard isVertical(v: v), v.translation.height > 0, detailsOffset == 0 else { return }
                            profileOpened = true
                            state = (-64 - v.translation.height).clamped(to: -68...0)
                        }
                        .updating($profileOffset) { v, state, transaction in
                            guard isVertical(v: v), v.translation.height > 0, detailsOffset == 0 else { return }
                            state = v.translation.height + 64
                        }
                        .updating($detailsOffset) { v, state, transaction in
                            guard  isVertical(v: v), profileOffset == 0 else { return }
                            blockTabView = true
                            if !detailsOpen && v.translation.height < 0 {
                                state = v.translation.height.clamped(to: detailsDragRange)
                        }
                }
                .onEnded { v in
                    defer { dragAxis = nil }
                    guard dragAxis == .vertical else { return }
                    blockTabView = false
                    let predicted = v.predictedEndTranslation.height
                    let openDetails = predicted < -50 && !detailsOpen && profileOffset == 0 && !profileOpened
                    
                    let distance = v.translation.height
                    let dismissThreshold: CGFloat = 50
                    print("distance \(distance)")
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
                
                ProfileDetailsView(screenWidth: screenWidth, p: vm.profileModel.profile, event: vm.profileModel.event, scrollSelection: $scrollSelection)
                    .offset(y: detailsStartingOffset + detailsOffset + detailsDismissOffset)
                    .offset(y: detailsOpen ? detailsOpenYOffset : 0)
                    .simultaneousGesture(
                        DragGesture()
                            .updating($detailsOffset) { v, state, _ in
                                guard isVertical(v: v) else { return }
                                state = v.translation.height.clamped(to: detailsDragRange)
                            }
                            .onEnded {
                                defer { dragAxis = nil }
                                guard dragAxis == .vertical else { return }

                                let predicted = $0.predictedEndTranslation.height
                                
                                if predicted < toggleDetailsThresh && profileOffset == 0 {
                                    detailsOpen = true
                                } else if detailsOpen && predicted > 60 {
                                    detailsOpen = false
                                }
                            }
                    )
                    .onTapGesture {detailsOpen.toggle()}
                    .padding(Edge.Set.horizontal, detailsPadding())
                    .transition(AnyTransition.move(edge: Edge.bottom))
                
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
            .onChange(of: detailsPadding()) { oldValue, newValue in
                detailsPad = newValue
                print("detailsPad: \(detailsPad)")
            }
            .colorBackground(.background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(radius: 10)
            .offset(y: profileOffset)
            .contentShape(Rectangle())
            .animation(.spring(duration: 0.2), value: detailsOpen)
            .animation(.easeOut(duration: 0.25), value: profileOffset)
            .animation(.easeInOut(duration: 0.2), value: detailsDismissOffset)
            .animation(.easeInOut(duration: 0.2), value: detailsOffset)
            .coordinateSpace(name: "profile")
            .onPreferenceChange(ScrollImageBottomValue.self) { y in
                if profileOffset != 0 {
                    print("Tried to updated but didn't")
                } else {
                    scrollImageBottomY  = y
                }
            }
            .onPreferenceChange(ImageWidthKey.self) {value in
                if value.isFinite, !value.isNaN {
                    imageSize = value
                }
                print("newValue = \(value)")
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
            profileDismissButton(selectedProfile: $selectedProfile, color: .black)
        }
        .font(.body(24, .bold))
        .padding(.horizontal)
        .opacity(isOverExtended ? (detailsOpen ? 0 : 1) : topOpacity())
    }
    
    @ViewBuilder
    private var invitePopup: some View {
        CustomScreenCover { vm.showInvitePopup = false }
        
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
                SelectTimeAndPlace(profile: vm.profileModel, onDismiss: { vm.showInvitePopup = false }) { event in
                    try? await meetVM.sendInvite(event: event, profileModel: vm.profileModel)
                    selectedProfile = nil
                }
            }
        }
    }
    
    private var detailsDragRange: ClosedRange<CGFloat> {
        detailsOpen ? (-85...220) : (-220...85)
    }
    
    private func isVertical(v: DragGesture.Value) -> Bool {
        if dragAxis == nil {
            let dx = abs(v.translation.width)
            let dy = abs(v.translation.height)
            let dragThresh: CGFloat = 5
            
            
            if max(dx, dy) >= dragThresh {
                dragAxis = dx > dy ? .horizontal : .vertical
            } else {
                return false
            }
        }
        return dragAxis == .vertical
    }
}

// All the functionality for animation when scrolling up and down

extension ProfileView {
    
    var isOverExtended: Bool {
        (detailsOpen && (detailsOffset < 0 || detailsOffset == 0)) || (!detailsOpen && detailsOffset > 0)
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
        
        if selectedProfile == nil {
            return 16
        } else if profileOffset > 0 {
            return max(initial - profileOffset, dismiss)
        } else {
           return detailsOpen ? lerp(0, initial, t) : lerp(initial, 0, t)
        }
        
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
        .padding(.top, 32)
        .padding(.horizontal, 16)
        .opacity(isOverExtended ? (detailsOpen ? 1 : 0) : title3Opacity())
    }
    
    func title3Opacity() -> Double {
        let one_third = max(1, abs(detailsOpenYOffset) / 3)
        let two_third = one_third * 2
        
        if detailsOpen {
            if abs(detailsOffset) < one_third {
                return 1 - min( detailsOffset / one_third, 1)
            } else {
                return 0
            }
        } else if !detailsOpen {
            if abs(detailsOffset) < two_third {
                return 0
            } else {
                return 0 + max( (abs(detailsOffset) - two_third) / one_third, 0)
            }
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
    
    func detailsPadding() -> CGFloat {
        let initial: CGFloat = 4, opened: CGFloat = 0
        return detailsOpen ? lerp(opened, initial, t)
                            : lerp(initial, opened, t)
    }
    
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
}

