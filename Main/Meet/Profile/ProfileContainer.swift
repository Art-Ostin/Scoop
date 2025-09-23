
import SwiftUI

struct ProfileView: View {
    
    @Environment(\.tabSelection) private var tabSelection
    @Environment(\.appDependencies) private var dep
    
    
    @Binding var selectedProfile: ProfileModel?
    @State private var vm: ProfileViewModel
    let meetVM: MeetViewModel?
    
    let preloadedImages: [UIImage]?
    
    
    @State var profileOffset: CGFloat = 0
    @State var startingOffset: CGFloat = UIScreen.main.bounds.height * 0.8
    @State var currentOffset: CGFloat = 0
    @State var endingOffset: CGFloat = 0
    var endingValue: CGFloat = -300
    
    @State var bottomImageValue: CGFloat = 0
    
    
    
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
                    .offset(y: startingOffset + currentOffset + endingOffset)
                    .toolbar(vm.showInvitePopup ? .hidden : .visible, for: .tabBar)
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
                    .padding(.top, bottomImageValue - (50 + 24)) //Taking away the Invite button height then adding padding of 24
                
            

                VStack(spacing: 24) {
                    HStack {
                          Text("profile Offset: \(profileOffset)")
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
            .colorBackground(.background)
            .ignoresSafeArea(edges: .top)
            .offset(y: profileOffset)
            .gesture (
                DragGesture()
                    .onChanged { v in
                        if v.translation.height > 0 {
                            profileOffset =  v.translation.height
                        }
                    }
                    .onEnded { value in
                        let predicted = value.predictedEndTranslation.height
                        
                        if profileOffset > 150 || predicted > 150 {
                            withAnimation(.spring()) { selectedProfile = nil }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                profileOffset = 0
                            }
                        } else {
                            withAnimation(.spring(duration: 0.2)) { profileOffset = 0 }
                        }
                    }
            )
            .onPreferenceChange(MainImageBottomValue.self) { bottom in
                if bottom < 750 {
                    bottomImageValue = bottom
                }
            }
        }
    }
    
    func topOpacity(currentOffset: CGFloat, endingOffset: CGFloat) -> Double {
        if endingOffset != 0 {
            return (0  + (abs(currentOffset) / 300))
        } else {
            return (1 - (abs(currentOffset) / 300))
        }
    }
    
    func topPadding(currentOffset: CGFloat, endingOffset: CGFloat) -> CGFloat {
        if endingOffset == 0 {
            let d = min(abs(currentOffset), 300)
            return max(84.0 - (84.0 * d / 300.0), 0)
        } else {
            let d = min(abs(currentOffset), 300)
            return min(0 + (84.0 * d / 300.0), 84.0)
        }
    }
    
    func topSpacing(currentOffset: CGFloat, endingOffset: CGFloat) -> CGFloat {
        let t = min(max(abs(currentOffset) / 300.0, 0), 1)
        return endingOffset != 0
            ? 36.0 * t
            : 36.0 * (1.0 - t)
    }
            
    
    

}

struct MainImageBottomValue: PreferenceKey {
    static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
         value += nextValue()
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
            NavButton(.down, 20) .onTapGesture {selectedProfile = nil}
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









/*
 .gesture (
  DragGesture()
      .onChanged { v in
          currentOffset = v.translation.height
          
          if endingOffset != 0 {
              currentOffset = max(currentOffset, -100)
          }
          
          if endingOffset == 0 {
              currentOffset = min(currentOffset, 50)
          }
      }
      .onEnded { value in
          let predicted = value.predictedEndTranslation.height
          withAnimation(.spring(duration: 0.2)) {
              if currentOffset < -10 {
                 endingOffset = endingValue
              } else {
                  endingOffset = 0
              }
              currentOffset = 0
          }
      }
)

 */

/*
 HStack {
                         Text("profile Offset: \(profileOffset)")
                         Text("current Offset: \(currentOffset)")
 }

 HStack {
                         Text("ending Offset: \(endingOffset)")
                         Text("starting Offset: \(startingOffset)")
     Text("bottomValue: \(bottomImageValue)")
 }

 */

/*
 
 func adaptiveTopPadding(currentOffset: CGFloat, endingOffset: CGFloat) -> CGFloat {
     if endingOffset == 0 && currentOffset > -68 {
         return 84 + currentOffset
     } else if endingOffset != 0 && currentOffset <= 68 {
         return 16 + currentOffset
     } else if (endingOffset != 0 && currentOffset > 68) || endingOffset == 0 {
         return 84
     } else {
         return 16
     }
 }
 */
