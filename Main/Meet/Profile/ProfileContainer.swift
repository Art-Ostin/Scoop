
import SwiftUI

struct ProfileView: View {
    ///MARK:
    @Environment(\.tabSelection) private var tabSelection
    @Environment(\.appDependencies) private var dep
    
    @State private var vm: ProfileViewModel
    let meetVM: MeetViewModel?
    let preloadedImages: [UIImage]?
    
    @Binding var selectedProfile: ProfileModel?
    
    @State var profileOffset: CGFloat = 0
    
    var detailsStartingOffset: CGFloat { scrollImageBottomY + 36 }
    @State var detailsOffset: CGFloat = 0
    @State var detailsOpen: Bool = false
    let detailsOpenYOffset: CGFloat = -170
    
    @State var imageBottomY: CGFloat = 0
    @State var scrollImageBottomY: CGFloat = 0
    
    let inviteButtonPadding: CGFloat = 24
    let inviteButtonSize: CGFloat = 50
    
    let toggleDetailsThresh: CGFloat = -50
    
    @State private var detailsDismissOffset: CGFloat = 0

    
    init(vm: ProfileViewModel, preloadedImages: [UIImage]? = nil, meetVM: MeetViewModel? = nil, selectedProfile: Binding<ProfileModel?>) {
        _vm = State(initialValue: vm)
        self.preloadedImages = preloadedImages
        self.meetVM = meetVM
        self._selectedProfile = selectedProfile
    }

    var body: some View {
        
        GeometryReader { proxy in
            let imageSize: CGFloat = proxy.size.width - 8
            ZStack(alignment: .topLeading) {
                
                
                VStack(spacing: topSpacing()) {
                    profileTitle
                        .padding(.top, topPadding())
                    ProfileImageView(preloaded: preloadedImages, vm: $vm, selectedProfile: $selectedProfile, detailsOffset: $detailsOffset, detailsOpen: $detailsOpen, detailsOpenYOffset: detailsOpenYOffset, imageSize: imageSize)
                }
                
                
                
                VStack {
                    HStack {
                        if detailsOpen { Text("Details Open")} else {Text("Details closed")}
                        
                        Text("topPadding: \(topPadding())")
                        
                        Text("topSpacing: \(topSpacing())")
                    }
                    
                    HStack {
                        Text("ProfileOffset: \(profileOffset)")
                        
                        Text("DragOffset: \(detailsOffset)")
                    }
                }
                .padding(.top, 250)
                
                
                ProfileDetailsView(dragOffset: $detailsOffset, detailsOpen: $detailsOpen, detailsOpenYOffset: detailsOpenYOffset, scrollImageBottomY: $scrollImageBottomY)
                    .offset(y: detailsStartingOffset + detailsOffset)
                    .offset(y: detailsOpen ? detailsOpenYOffset : 0)
                    .offset(y: detailsDismissOffset)
                
                    .onTapGesture {detailsOpen.toggle() }
                    .gesture (
                        DragGesture()
                            .onChanged {
                                
                                let range: ClosedRange<CGFloat> = detailsOpen ? (-35...220) : (-220...35)
                                
                                detailsOffset = $0.translation.height.clamped(to: range)
                                
                                
                                /*
                                 if detailsOpen  {
                                     if detailsOffset > -35 {
                                         detailsOffset = $0.translation.height
                                     }
                                 } else {
                                     if detailsOffset < 35 {
                                         detailsOffset = $0.translation.height
                                     }
                                 }
                                 */
                                
                                
                            }

                            .onEnded {
                                let predicted = $0.predictedEndTranslation.height

                                    if detailsOffset < toggleDetailsThresh || predicted <  toggleDetailsThresh {
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
                            
                            detailsDismissOffset = min(max(-dragAmount * 1.5, -68), 0)
                            
                        } else if !detailsOpen {
                            
                            let range: ClosedRange<CGFloat> = detailsOpen ? (-35...220) : (-220...35)
                            
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
                        
                        if openDetails || closeDetails { detailsOpen.toggle()
}
                        detailsDismissOffset = 0
                        detailsOffset = 0
                        profileOffset = 0
                    }
            )
            .toolbar(vm.showInvitePopup ? .hidden : .visible, for: .tabBar)
            .animation(.spring(duration: 0.2), value: detailsOffset)
            .animation(.spring(duration: 0.2), value: detailsOpen)


            
            .onPreferenceChange(ScrollImageBottomValue.self) { y in
                if profileOffset != 0 {
                    print("Tried to updated but didn't")
                } else {
                    scrollImageBottomY  = y
                }
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
            return (0  + (abs(detailsOffset) / abs(detailsOpenYOffset)))
        } else {
            return (1 - (abs(detailsOffset) / abs(detailsOpenYOffset)))
        }
    }
    
    
    func topPadding() -> CGFloat {
        
        let initial: CGFloat = 84
        let dismiss: CGFloat = 16
        
        let t = min(max(abs(detailsOffset) / abs(detailsOpenYOffset), 0), 1)
        
        if profileOffset > 0 {
            return (selectedProfile == nil) ? dismiss : max(initial - profileOffset, dismiss)
        }
        
        return detailsOpen ? initial * t : initial * (1 - t)
    }
    
    func topSpacing() -> CGFloat {
        
        let maxSpacing: CGFloat = 36
        let minSpacing: CGFloat = 0
        
        let currentSpacing: CGFloat = maxSpacing * abs(detailsOffset) / abs(detailsOpenYOffset)
        
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

/*
 .onPreferenceChange(MainImageBottomValue.self) { bottom in
     imageBottomY = bottom
 }

 */
