
import SwiftUI

struct ProfileView: View {
    
    @Environment(\.tabSelection) private var tabSelection
    @Environment(\.appDependencies) private var dep
    @State private var vm: ProfileViewModel
    
    let meetVM: MeetViewModel?
    
    let preloadedImages: [UIImage]?
    let onDismiss: () -> Void
    
    @State var profileOffset: CGFloat = 0
    @Binding var selectedProfile: ProfileModel?
    
    
    @State var startingOffset: CGFloat = UIScreen.main.bounds.height * 0.75
    @State var currentOffset: CGFloat = 0
    @State var endingOffset: CGFloat = 0
    
    
    var endingValue: CGFloat = -300
    
    
    
    init(vm: ProfileViewModel, preloadedImages: [UIImage]? = nil, meetVM: MeetViewModel? = nil, selectedProfile: Binding<ProfileModel?>, onDismiss: @escaping () -> Void) {
        _vm = State(initialValue: vm)
        self.preloadedImages = preloadedImages
        self.onDismiss = onDismiss
        self.meetVM = meetVM
        self._selectedProfile = selectedProfile
    }
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack(alignment: .top) {
                VStack(spacing: 24) {
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
                            .font(.body(20, .bold))
                            .onTapGesture {
                                onDismiss()
                            }
                    }
                    .padding(.top, topOffset(currentOffset, endingOffset))
                    .padding(.horizontal)
                    ProfileImageView(size: size, vm: $vm, preloaded: preloadedImages, currentOffset: $currentOffset, endingOffset: $endingOffset)
                    if endingOffset != 0 {
                        Spacer()
                    }
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
                    .gesture (
                        DragGesture()
                            .onChanged { v in
                                currentOffset = v.translation.height
                            }
                            .onEnded { value in
                                let predicted = value.predictedEndTranslation.height
                                withAnimation(.spring()) {
                                    if currentOffset < -100 || predicted < -150  {
                                        withAnimation(.spring(duration: 0.2)) { endingOffset = endingValue }
                                    } else {
                                        withAnimation(.spring(duration: 0.2)) { endingOffset = 0 }
                                    }
                                    currentOffset = 0
                                 }
                            }
                    )
                VStack {
                    HStack {
                        Text("profile Offset: \(profileOffset)")
                        Text("current Offset: \(currentOffset)")
                    }
                    
                    HStack {
                        Text("ending Offset: \(endingOffset)")
                        Text("starting Offset: \(startingOffset)")
                    }
                }
                .padding(.top, 250)
                
                if vm.showInvitePopup { invitePopup }
            }
            .background {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.background)
            }
            .ignoresSafeArea(edges: .all)
            .offset(y: profileOffset)
            .gesture (
                DragGesture()
                    .onChanged { v in
                        if v.translation.height > 0 {
                            profileOffset =  v.translation.height
                        }
                    }
                    .onEnded { value in
                        if (selectedProfile != nil) && profileOffset > 150 {
                            withAnimation(.spring()) { selectedProfile = nil }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                profileOffset = 0
                            }
                        } else if currentOffset < -64 {
                            withAnimation(.spring(duration: 0.2)) { currentOffset = endingValue }
                        } else {
                            withAnimation(.spring(duration: 0.2)) { profileOffset = 0 }
                        }
                    }
            )
        }
    }

    private func topOffset(_ currentOffset: CGFloat, _ endingOffset: CGFloat) -> CGFloat {
        if currentOffset != 0 && endingOffset == 0 {
            return 84 + currentOffset
        } else if endingOffset != 0 {
            return -36
        } else {
            return 84
        }
    }
}


extension ProfileView {
    
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
                    onDismiss()
                })
            }
        }
    }
}

/*
 @State var imageZoom: CGFloat = 1
 */
