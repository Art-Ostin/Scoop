

import SwiftUI

struct ProfileView: View {
    
    @State var vm = ProfileViewModel()
    @Binding var state: MeetSections
    @State var isInviting: Bool = false
    
    let name = Profile.currentUser?.name ?? ""
    let nationality = Profile.currentUser?.nationality ?? []

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
