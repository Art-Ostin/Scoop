
import SwiftUI

struct ProfileView: View {
    
    @Environment(\.tabSelection) private var tabSelection
    @Environment(\.appDependencies) private var dep
    
    @State private var vm: ProfileViewModel
    
    let meetVM: MeetViewModel?

    let preloadedImages: [UIImage]?
    
    @Binding var selectedProfile: ProfileModel?
    
    @State private var profileOffset: CGFloat = 0

    private var cornerRadius: CGFloat {
        (selectedProfile != nil) ? max(0, min(30, profileOffset / 3)) : 30
    }
    
    
    
    
    @State var detailsOffset: CGFloat = 0
    @State var detailsEndingOffset: CGFloat = 0
    
    
    @State var endingValue: CGFloat = -170
    @State var detailsViewHeight: CGFloat = 170
    
    
    @State var bottomImageValue: CGFloat = 0
    @State private var scrollBottomImageValue: CGFloat = 0
    
    var detailScrolling: Bool {detailsOffset != 0}
    
    
    
    
    
    
    init(vm: ProfileViewModel, preloadedImages: [UIImage]? = nil, meetVM: MeetViewModel? = nil, selectedProfile: Binding<ProfileModel?>) {
        _vm = State(initialValue: vm)
        self.preloadedImages = preloadedImages
        self.meetVM = meetVM
        self._selectedProfile = selectedProfile
    }
    
    var body: some View {
        
        let baseY = (scrollBottomImageValue + 36) - profileOffset
        
        
        GeometryReader { proxy in
            
            ZStack(alignment: .top) {
                
                VStack(spacing: topSpacing(currentOffset: detailsOffset, detailsEndingOffset: detailsEndingOffset)) {
                    
                    profileTitle
                        .opacity(topOpacity(currentOffset: detailsOffset, detailsEndingOffset: detailsEndingOffset))
                    
                        .padding(.top, topPadding(currentOffset: detailsOffset, detailsEndingOffset: detailsEndingOffset))
                    
                    ProfileImageView(proxy: proxy, vm: $vm, preloaded: preloadedImages, selectedProfile: $selectedProfile, currentOffset: $detailsOffset, endingOffset: $detailsEndingOffset)
                    
                }
                    
                ProfileDetailsView(dragOffset: $detailsOffset, endingOffset: $detailsEndingOffset, endingValue: endingValue)
                        .offset(y: baseY + detailsOffset + detailsEndingOffset)
                

                }
                
                InviteButton(vm: $vm)
                    .frame(maxWidth: .infinity, alignment: .trailing) // stick to the right
                    .padding(.trailing, (24 + 4)) // there is 4px padding on the images, then adding padding inside of 24
                    .padding(.top, (bottomImageValue - 74))
                    .padding(.top, profileOffset > 48 ? -profileOffset : 0) //Taking away the Invite button height (50) then adding padding of 24
                    .ignoresSafeArea()
                
                
                VStack(spacing: 24) {
                    HStack {
                        Text("profile Offset: \(profileOffset)")
                        Text("scoll image bottom: \(scrollBottomImageValue)")
                        Text("current Offset: \(detailsOffset)")
                    }
                    
                    HStack {
                        Text("ending Offset: \(detailsEndingOffset)")
                        Text("bottomValue: \(bottomImageValue)")
                    }
                }
                .padding(.top, 250)
                
                if vm.showInvitePopup { invitePopup }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(radius: cornerRadius > 0 ? 10 : 0)
            .contentShape(Rectangle())
            .offset(y: profileOffset)
            .coordinateSpace(name: "profile")
            .gesture (
                DragGesture()
                    .onChanged { v in
                        if v.translation.height > 0 {
                            withAnimation(.spring()){
                                profileOffset = v.translation.height * 1.5
                            }
                        } else if detailsEndingOffset == 0  {
                            detailsOffset = v.translation.height
                        }
                    }
                
                    .onEnded {  value in
                        if profileOffset > 180 {
                            withAnimation(.easeInOut(duration: 0.25)) { selectedProfile = nil }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                profileOffset = 0
                            }
                        } else if detailsOffset < -50 {
                            let predicted = value.predictedEndTranslation.height
                            withAnimation(.spring(duration: 0.2)) {
                                if detailsOffset < -50 || predicted < -50 {
                                    detailsEndingOffset = endingValue
                                } else if detailsEndingOffset != 0 && detailsOffset > 60 {
                                    detailsEndingOffset = 0
                                }
                                detailsOffset = 0
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) { profileOffset = 0 }
                            detailsOffset = 0
                        }
                    }
            )
            .toolbar(vm.showInvitePopup ? .hidden : .visible, for: .tabBar)
            .onPreferenceChange(MainImageBottomValue.self) { bottom in
                bottomImageValue = bottom
            }
            .onPreferenceChange(ScrollImageBottomValue.self) { y in
                if abs(y - scrollBottomImageValue) > 0.5 {
                    scrollBottomImageValue = y
                }
            }
        }
}


struct MainImageBottomValue: PreferenceKey {
    static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ScrollImageBottomValue: PreferenceKey {
    static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}



extension ProfileView {
    
    private var profileTitle: some View {
        HStack {
            let p = vm.profileModel.profile
            Text(p.name)
                .font(.body(24, .bold))
            ForEach (p.nationality, id: \.self) {flag in
                Text(flag)
                    .font(.body(24))
            }
            Spacer()
            
            Image(systemName: "chevron.down")
                .font(.body(18, .medium))
                .foregroundStyle(Color(red: 0.3, green: 0.3, blue: 0.3))
                .contentShape(Rectangle())
                .onTapGesture {selectedProfile = nil}
            }
        .padding(.horizontal)
    }
    
    
    @ViewBuilder
    private var invitePopup: some View {
        Rectangle()
            .fill(.thinMaterial)
            .ignoresSafeArea()
            .contentShape(Rectangle())
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
    func topOpacity(currentOffset: CGFloat, detailsEndingOffset: CGFloat) -> Double {
        if detailsEndingOffset != 0 {
            return (0  + (abs(currentOffset) / detailsViewHeight))
        } else {
            return (1 - (abs(currentOffset) / detailsViewHeight))
        }
    }
    
    func topPadding(currentOffset: CGFloat, detailsEndingOffset: CGFloat) -> CGFloat {
        
        if profileOffset > 0 {
            return ( selectedProfile == nil ? 16 :  max(84 - profileOffset, 16) )
        } else if detailsEndingOffset == 0 {
            let d = min(abs(currentOffset), detailsViewHeight)
             return max(84.0 - (84.0 * d / detailsViewHeight), 0)
        } else {
            let d = min(abs(currentOffset), detailsViewHeight)
            return min(0 + (84.0 * d / detailsViewHeight), 84.0)
        }
    }
    
    func topSpacing(currentOffset: CGFloat, detailsEndingOffset: CGFloat) -> CGFloat {
        let t = min(max(abs(currentOffset) / detailsViewHeight, 0), 1)
        return detailsEndingOffset != 0
            ? 36.0 * t
            : 36.0 * (1.0 - t)
    }
}


private struct ImageBottomKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}


extension View {
    
    func reportBottom<Key: PreferenceKey>(in space: String, as key: Key.Type) -> some View where Key.Value == CGFloat {
        background (
            GeometryReader { g in
                Color.clear
                    .preference(key: key, value: g.frame(in: .named(space)).maxY)
            }
        )
    }
}
