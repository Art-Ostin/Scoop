
import Foundation
import SwiftUI

struct ProfileView: View {
    
    @Environment(\.tabSelection) private var tabSelection
    @Environment(\.appDependencies) private var dep
    @State private var vm: ProfileViewModel
    let meetVM: MeetViewModel?
    
    @State var imageZoom: CGFloat = 1
    
    let preloadedImages: [UIImage]?
    let onDismiss: () -> Void
    
    
    init(vm: ProfileViewModel, preloadedImages: [UIImage]? = nil, meetVM: MeetViewModel? = nil, onDismiss: @escaping () -> Void) {
        _vm = State(initialValue: vm)
        self.preloadedImages = preloadedImages
        self.onDismiss = onDismiss
        self.meetVM = meetVM
    }
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                Color.background.edgesIgnoringSafeArea(.all)
                ScrollView(showsIndicators: false) {

                    VStack(spacing: 24) {
                            heading
                            ProfileImageView(size: size, vm: $vm, preloaded: preloadedImages, imageZoom: $imageZoom)
                        }
                    
                    ProfileDetailsView()
                    
                }
                .toolbar(vm.showInvitePopup ? .hidden : .visible, for: .tabBar)
                if vm.showInvitePopup { invitePopup }
            }
        }
    }
}


extension ProfileView {
    
    private var heading: some View {
        let p = vm.profileModel.profile
        return HStack {
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
        .padding(.horizontal)
        .padding(.top, 72)
        
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
                    onDismiss()
                })
            }
        }
    }
}
