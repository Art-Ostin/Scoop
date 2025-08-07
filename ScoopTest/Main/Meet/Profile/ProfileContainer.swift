
import Foundation

@Observable class ProfileViewModel {
    
    var p: UserProfile
    
    let dep: AppDependencies
    
    var images =  Task {
        await dep.imageCache.fetchProfileImages(profiles: [p])
    }
    
    
    var invitePopup: Bool = false
    var showInviteButton: Bool
    
    var imageSelection: Int = 0
    let pageSpacing: CGFloat = -48
    
    init(profile: UserProfile, showInviteButton: Bool, dep: AppDependencies) {
        self.p = profile
        self.showInviteButton = showInviteButton
        self.dep = dep
    }
}






import SwiftUI

struct ProfileView: View {
    
    @Environment(\.appDependencies) private var dep
    @Environment(\.dismiss) private var dismiss
    
    @State private var vm: ProfileViewModel
    
    var vm2: Binding<MeetUpViewModel>?
    
    var showInviteButton: Bool
    
    init(profile: UserProfile, vm2: Binding<MeetUpViewModel>? = nil, showInviteButton: Bool = true, dep: AppDependencies) {
        self._vm = State(initialValue: ProfileViewModel(profile: profile, showInviteButton: showInviteButton, dep: dep))
        self.vm2 = vm2
        self.showInviteButton = showInviteButton
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
                                
                                ProfileImageView(vm: $vm)
                                    .frame(height: 420)
                                
                                ProfileImageScroller(vm: $vm)
                            }
                            .frame(maxHeight: .infinity, alignment: .top)
                            ProfileDetailsView(vm: $vm)
                        }
                    }
                    if vm.invitePopup  && (vm.showInviteButton == true), let user = dep.userStore.user?.userId {
                        Rectangle()
                            .fill(.thinMaterial)
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                vm.invitePopup = false
                            }
                        SendInviteView(profile1: user, profile2: vm.p, profileVM: $vm)
                    }
                }
            }
            .toolbar(vm.invitePopup ? .hidden : .visible, for: .tabBar)
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
