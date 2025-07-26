

import SwiftUI

struct ProfileView: View {
    
    @State private var vm: ProfileViewModel
    @Binding var state: MeetSections
    
    @State var isInviting: Bool = false
    
    
    init(profile: UserProfile, state: Binding<MeetSections>) {
        self._vm = State(initialValue: ProfileViewModel(profile: profile))
        self._state = state
    }
    
    
    var body: some View {
        
        GeometryReader { _ in
            
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
                    SendInviteView(ProfileViewModel: vm, name: vm.profile.name ?? "")
                }
            }
        }
    }
}
#Preview{
    ProfileView(profile: EditProfileViewModel.instance.user!, state: .constant(.profile))
}

extension ProfileView {

    private var heading: some View {
        HStack {
            Text(vm.profile.name ?? "")
                .font(.body(24, .bold))
            ForEach (vm.profile.nationality ?? [], id: \.self) {flag in
                Text(flag)
                    .font(.body(24))
            }
            Spacer()
            Image(systemName: "chevron.down")
                .font(.body(20, .bold))
                .onTapGesture { state = .twoDailyProfiles }
        }
    }
}
