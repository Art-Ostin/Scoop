






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
    
    @Environment(\.dismiss) private var dismiss
    @State private var vm: ProfileViewModel
    @Binding var state: MeetSections?
    @State var isInviting: Bool = false
    
    init(profile: UserProfile, state: Binding<MeetSections?> = .constant(nil)) {
        self._vm = State(initialValue: ProfileViewModel(profile: profile))
        self._state = state
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
                    if vm.showInvite {
                        Rectangle().fill(.regularMaterial) .ignoresSafeArea(.all)
                        SendInviteView(ProfileViewModel: vm, name: vm.p.name ?? "")
                    }
                }
            }
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
                    if state != nil {
                        state = .twoDailyProfiles
                    } else {
                        dismiss()
                    }
                }
        }
    }
}
