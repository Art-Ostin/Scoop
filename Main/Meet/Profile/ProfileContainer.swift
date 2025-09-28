
import SwiftUI

struct ProfileView: View {
    
    @Environment(\.tabSelection) private var tabSelection
    @Environment(\.appDependencies) private var dep
    
    @State private var vm: ProfileViewModel
    let meetVM: MeetViewModel?
    let preloadedImages: [UIImage]?
    
    @Binding var selectedProfile: ProfileModel?
    
    @State var profileOffset: CGFloat = 0
    @State var detailsOffset: CGFloat = 0
    
    @State var detailsOpen: Bool = false
    let detailsOpenYOffset: CGFloat = -170
    
    @State var imageBottomY: CGFloat = 0
    @State var scrollImageBottomY: CGFloat = 0
    
    let inviteButtonPadding: CGFloat = 24
    let inviteButtonSize: CGFloat = 50
    
    init(vm: ProfileViewModel, preloadedImages: [UIImage]? = nil, meetVM: MeetViewModel? = nil, selectedProfile: Binding<ProfileModel?>) {
        _vm = State(initialValue: vm)
        self.preloadedImages = preloadedImages
        self.meetVM = meetVM
        self._selectedProfile = selectedProfile
    }
    
        
    
    
    var body: some View {
                
        
        GeometryReader { proxy in
            
            let imageSize: CGFloat = proxy.size.width - 8

            
            ZStack(alignment: .top) {
                
                VStack(spacing: topSpacing()) {
                    
                    profileTitle
                        .padding(.top, topPadding())
                    
                    ProfileImageView(preloaded: preloadedImages, vm: $vm, selectedProfile: $selectedProfile, detailsOffset: $detailsOffset, detailsOpen: $detailsOpen, detailsOpenYOffset: detailsOpenYOffset, imageSize: imageSize)
                }
                
                
                ProfileDetailsView(dragOffset: $detailsOffset, detailsOpen: $detailsOpen, detailsOpenYOffset: detailsOpenYOffset)
                
                
                InviteButton(vm: $vm)
                    .offset (
                        x: imageSize - inviteButtonSize - inviteButtonPadding,
                        y: topPadding() + topSpacing() + imageSize - (inviteButtonSize)
                    )
                
                
                
                
                if vm.showInvitePopup { invitePopup }
            }
            
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.background)
            .clipShape(RoundedRectangle(cornerRadius: (selectedProfile != nil) ? max(0, min(30, profileOffset / 3)) : 30, style: .continuous))
            .shadow(radius: 10)
            .contentShape(Rectangle())
            .offset(y: profileOffset)
            .coordinateSpace(name: "profile")
            .gesture (
                DragGesture()
                    .onChanged {

                        let dragAmount = $0.translation.height
                        let dragDown = dragAmount > 0
                        
                        if dragDown {
                            profileOffset = dragAmount * 1.5
                        } else if !detailsOpen {
                            detailsOffset = dragAmount
                        }
                    }
                
                
                    .onEnded {
                        let predicted = $0.predictedEndTranslation.height
                        let closeProfile = profileOffset > 180
                        
                        let openDetails = detailsOffset < -50 || predicted < -50
                        let closeDetails = detailsOpen && detailsOffset > 60
                        
                        
                        if closeProfile {
                            withAnimation(.easeInOut(duration: 0.25)) { selectedProfile = nil }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { profileOffset = 0 }
                            return
                        }
                        
                        if openDetails {
                            withAnimation(.spring(duration: 0.2)) {detailsOpenYOffset}
                            detailsOpen = true
                        }
                        
                        if openDetails || closeDetails {
                            withAnimation(.spring(duration: 0.2)) {
                                detailsOpen ? detailsOpenYOffset : 0
                                detailsOffset = 0
                            }
                        }
                    }
            )

            
            .toolbar(vm.showInvitePopup ? .hidden : .visible, for: .tabBar)
            .onPreferenceChange(MainImageBottomValue.self) { bottom in
                imageBottomY = bottom
            }
            .onPreferenceChange(ScrollImageBottomValue.self) { y in
                scrollImageBottomY = y
                }
            }
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
        .opacity(topOpacity())
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
    
    func topOpacity() -> Double {
        if detailsOpen {
            return (0  + (abs(detailsOffset) / detailsOpenYOffset))
        } else {
            return (1 - (abs(detailsOffset) / detailsOpenYOffset))
        }
    }
    
    func topPadding() -> CGFloat {
        
        let dismissingProfile = profileOffset > 0
        let profileDismissed = selectedProfile == nil
        
        let initialPadding: CGFloat = 84
        let dismissPadding: CGFloat = 16
        let currentPadding: CGFloat = initialPadding * abs(detailsOffset) / detailsOpenYOffset
        
        if dismissingProfile {
            return profileDismissed ? dismissPadding : max(initialPadding - profileOffset, dismissPadding)
        }
        else if detailsOpen {
            return  0 + min(currentPadding, initialPadding)
        } else {
            return initialPadding - max(currentPadding, initialPadding)
        }
    }
    
    func topSpacing() -> CGFloat {
        
        let maxSpacing: CGFloat = 36
        let minSpacing: CGFloat = 0
        
        let currentSpacing: CGFloat = maxSpacing * abs(detailsOffset) / detailsOpenYOffset
        
        if detailsOpen {
            return minSpacing + min(currentSpacing, maxSpacing)
        } else {
            return maxSpacing - max(currentSpacing, minSpacing)
        }
    }
}





/*
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

 */

/*
 */


/*
 .onEnded {
     if profileOffset > 180 {
         withAnimation(.easeInOut(duration: 0.25)) { selectedProfile = nil }
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
             profileOffset = 0
         }
         
     } else if detailsOffset < -50 {
         let predicted = $0.predictedEndTranslation.height
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
 */


/*
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

 */


/*
 Modifiers for Invite button
     .frame(maxWidth: .infinity, alignment: .trailing)
     .padding(.trailing, (24 + 4))
     .padding(.top, (imageBottomY - 74))
     .padding(.top, profileOffset > 55 ? -profileOffset : 0) //Taking away the Invite button height (50) then adding padding of 24
     .ignoresSafeArea()
 */
