
import SwiftUI

struct ProfileView: View {
    
    @Environment(\.tabSelection) private var tabSelection
    @Environment(\.appDependencies) private var dep
    
    
    @State private var vm: ProfileViewModel
    let meetVM: MeetViewModel?
    
    let preloadedImages: [UIImage]?
    
    
    @State private var profileOffset: CGFloat = 0
    @Binding var selectedProfile: ProfileModel?

    private var cornerRadius: CGFloat {
        (selectedProfile != nil) ? max(0, min(30, profileOffset / 3)) : 30
    }
    
    @State var startingOffset: CGFloat = UIScreen.main.bounds.height * 0.8
    @State var currentOffset: CGFloat = 0
    @State var endingOffset: CGFloat = 0
    var endingValue: CGFloat = -170
    var detailsViewHeight: CGFloat = 170
    @State var bottomImageValue: CGFloat = 0
    
    @State private var scrollBottomImageValue: CGFloat = 0
    
    @State var mainOffset: CGFloat = 0
    
    
    
    init(vm: ProfileViewModel, preloadedImages: [UIImage]? = nil, meetVM: MeetViewModel? = nil, selectedProfile: Binding<ProfileModel?>) {
        _vm = State(initialValue: vm)
        self.preloadedImages = preloadedImages
        self.meetVM = meetVM
        self._selectedProfile = selectedProfile
    }
    
    var body: some View {
        
        GeometryReader { proxy in
            
            ZStack(alignment: .top) {
                
                VStack(spacing: topSpacing(currentOffset: currentOffset, endingOffset: endingOffset)) {
                    
                    profileTitle
                        .opacity(topOpacity(currentOffset: currentOffset, endingOffset: endingOffset))
                    
                        .padding(.top, topPadding(currentOffset: currentOffset, endingOffset: endingOffset))

                    ProfileImageView(proxy: proxy, vm: $vm, preloaded: preloadedImages, selectedProfile: $selectedProfile, currentOffset: $currentOffset, endingOffset: $endingOffset)
                }
                
                ProfileDetailsView()
                    .offset(y: (scrollBottomImageValue + 36) - profileOffset)
                    .offset(y:currentOffset + endingOffset)
                    .onTapGesture {
                        if endingOffset == 0 {
                            withAnimation(.spring(duration: 0.2)) { endingOffset = endingValue }
                        } else {
                            withAnimation(.spring(duration: 0.2)) { endingOffset = 0 }
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                withAnimation(.spring(duration: 0.2)){
                                    currentOffset = value.translation.height
                                }
                            }
                            .onEnded {  value in
                                let predicted = value.predictedEndTranslation.height
                                withAnimation(.spring(duration: 0.2)) {
                                    if currentOffset < -50 || predicted < -50 {
                                        endingOffset = endingValue
                                    } else if endingOffset != 0 && currentOffset > 60 {
                                        endingOffset = 0
                                    }
                                    currentOffset = 0
                                }
                            }
                    )
                
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
                           Text("current Offset: \(currentOffset)")
                     }

                     HStack {
                         Text("ending Offset: \(endingOffset)")
                          Text("starting Offset: \(startingOffset)")
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
            .gesture (
                DragGesture()
                    .onChanged { v in
                        
                        if v.translation.height > 0 {
                            withAnimation(.spring()){
                                profileOffset = v.translation.height * 1.5
                            }
                        } else {
                            if endingOffset == 0 {
                                currentOffset = v.translation.height
                            }
                        }
                    }
                    .onEnded {  value in
                        withAnimation(.spring()) {
                            if profileOffset > 180 {
                                withAnimation(.easeOut(duration: 0.4)) { selectedProfile = nil }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    profileOffset = 0
                                }
                            } else if currentOffset < -50 {
                                let predicted = value.predictedEndTranslation.height
                                withAnimation(.spring(duration: 0.2)) {
                                    if currentOffset < -50 || predicted < -50 {
                                        endingOffset = endingValue
                                    } else if endingOffset != 0 && currentOffset > 60 {
                                        endingOffset = 0
                                    }
                                    currentOffset = 0
                                }
                            } else {
                                profileOffset = 0
                            }
                        }
                    }
            )
            .toolbar(vm.showInvitePopup ? .hidden : .visible, for: .tabBar)
            .onPreferenceChange(MainImageBottomValue.self) { bottom in
                bottomImageValue = bottom
            }
            .onPreferenceChange(ScrollImageBottomValue.self) { bottom in
                scrollBottomImageValue = bottom
            }
        }
    }
    
    func topOpacity(currentOffset: CGFloat, endingOffset: CGFloat) -> Double {
        if endingOffset != 0 {
            return (0  + (abs(currentOffset) / detailsViewHeight))
        } else {
            return (1 - (abs(currentOffset) / detailsViewHeight))
        }
    }
    
    func topPadding(currentOffset: CGFloat, endingOffset: CGFloat) -> CGFloat {
        
        if profileOffset > 0 {
            return ( selectedProfile == nil ? 16 :  max(84 - profileOffset, 16) )
        } else if endingOffset == 0 {
            let d = min(abs(currentOffset), detailsViewHeight)
            return max(84.0 - (84.0 * d / detailsViewHeight), 0)
        } else {
            let d = min(abs(currentOffset), detailsViewHeight)
            return min(0 + (84.0 * d / detailsViewHeight), 84.0)
        }
    }
    
    func topSpacing(currentOffset: CGFloat, endingOffset: CGFloat) -> CGFloat {
        let t = min(max(abs(currentOffset) / detailsViewHeight, 0), 1)
        return endingOffset != 0
            ? 36.0 * t
            : 36.0 * (1.0 - t)
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
