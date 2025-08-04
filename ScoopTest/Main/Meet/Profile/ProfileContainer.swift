
import Foundation

@Observable class ProfileViewModel {
    
    var p: UserProfile

    var showInvite: Bool = false
    var inviteSent: Bool = false
    
    var imageSelection: Int = 0
    let pageSpacing: CGFloat = -48
    
    init(profile: UserProfile) {
        self.p = profile
    }
    
}

import SwiftUI


struct ProfileView: View {
    
    @Environment(\.appDependencies) private var dep
    @Environment(\.dismiss) private var dismiss
    @State private var vm: ProfileViewModel
    
    var vm2: Binding<MeetUpViewModel>?
    @State var isInviting: Bool = false
    
    init(profile: UserProfile, vm2: Binding<MeetUpViewModel>? = nil) {
        self._vm = State(initialValue: ProfileViewModel(profile: profile))
        self.vm2 = vm2
    }
    
    
    var body: some View {
        
        GeometryReader { _ in
            NavigationStack {
                ZStack {
                    Color.background.edgesIgnoringSafeArea(.all)
                    ScrollView {
                        VStack {
                            VStack {
                                heading
                                    .padding()
                                
                                ProfileImageView(vm: $vm, isInviting: $isInviting)
                                    .frame(height: 420)
                                
                                ProfileImageScroller(vm: $vm)
                            }
                            .frame(maxHeight: .infinity, alignment: .top)
                            ProfileDetailsView(vm: $vm)
                        }
                    }
                    if vm.showInvite && (vm.inviteSent == false), let user = dep.userStore.user?.userId {
                        Rectangle()
                            .fill(.thinMaterial)
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                vm.showInvite = false
                            }
                        SendInviteView(profile1: user, profile2: vm.p, profileVM: $vm)
                    }
                }
            }
            .toolbar(vm.showInvite ? .hidden : .visible, for: .tabBar)
        }
    }
}

extension ProfileView {
    
    private var heading: some View {
        HStack {
            Text(vm.p.name ?? "")
                .font(.body(24, .bold))
            ForEach (vm.p.nationality ?? [], id: \.self) {flag in
                Text(flag)
                    .font(.body(24))
            }
            Spacer()
            Image(systemName: "chevron.down")
                .font(.body(20, .bold))
                .onTapGesture {
                    if let vm2 {
                        vm2.wrappedValue.state = .twoDailyProfiles
                    } else {
                        dismiss()
                    }
                }
        }
    }
}
