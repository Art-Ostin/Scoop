

import SwiftUI

import Foundation
import SwiftUI


//Have this profile viewModel

@Observable class ProfileViewModel {
    
    var profile: UserProfile
    
    var showInvite: Bool = false
    var inviteSent: Bool = false
    
    var imageSelection: Int = 0
    let pageSpacing: CGFloat = -48
    
    init(profile: UserProfile) {
        self.profile = profile
    }
}



struct ProfileView: View {
    
    
    @State var vm = ProfileViewModel(profile: EditProfileViewModel.instance.user!)
    
        
    
    @Binding var state: MeetSections
    @State var isInviting: Bool = false
    
    let name = EditProfileViewModel.instance.user?.name ?? ""
    let nationality = EditProfileViewModel.instance.user?.nationality ?? []

    var body: some View {
        
        GeometryReader { geo in
            
            ZStack {
                Color.background.edgesIgnoringSafeArea(.all)
                VStack {
                    heading
                        .padding()

                    ProfileImageView(vm: $vm, isInviting: $isInviting)
                        .frame(height: 420)
                
                    ProfileImageScroller(vm: $vm)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                
                ProfileDetailsView(vm: $vm)

                if vm.showInvite {
                    Rectangle()
                        .fill(.regularMaterial)
                        .ignoresSafeArea(.all)
                    SendInviteView(ProfileViewModel: vm, name: "Arthur")
                }
            }
        }
    }
}
#Preview {
    ProfileView(state: .constant(.profile))
}

extension ProfileView {

    private var heading: some View {
        HStack {
            Text(name)
                .font(.body(24, .bold))
            ForEach (nationality, id: \.self) {flag in
                Text(flag)
                    .font(.body(24))
            }
            Spacer()
            Image(systemName: "chevron.down")
                .font(.body(20, .bold))
                .onTapGesture {
                    state = .twoDailyProfiles
                }
        }
    }
}
