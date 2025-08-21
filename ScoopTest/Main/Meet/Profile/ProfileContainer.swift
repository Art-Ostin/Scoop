
import Foundation
import SwiftUI

struct ProfileView: View {
    
    @Environment(\.appDependencies) private var dep
    @State private var vm: ProfileViewModel
    
    let onDismiss: () -> Void
    
    init(vm: ProfileViewModel, onDismiss: @escaping () -> Void = {}) {
        _vm = State(initialValue: vm)
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        
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
                        }
                        .frame(maxHeight: .infinity, alignment: .top)
                        ProfileDetailsView(vm: $vm)
                    }
                }
                
                if vm.showInvitePopup {
                    Rectangle()
                        .fill(.thinMaterial)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { vm.showInvitePopup = false }
                    if (vm.profileModel.event != nil) {
                        AcceptInvitePopup(vm: InviteViewModel(eventManager: dep.eventManager, cycleManager: dep.cycleManager, profileModel: vm.profileModel)) {
                            onDismiss()
                        }
                    } else {
                        SendInvitePopup(vm: InviteViewModel(eventManager: dep.eventManager, cycleManager: dep.cycleManager, profileModel: vm.profileModel)) {
                            onDismiss()
                        }
                    }
                }
            }
            .toolbar(vm.showInvitePopup ? .hidden : .visible, for: .tabBar)
        }
    }
}

extension ProfileView {

    private var heading: some View {
        let p = vm.profileModel.profile
        return HStack {
            Text(p.name ?? "")
                .font(.body(24, .bold))
            ForEach (p.nationality ?? [], id: \.self) {flag in
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
    }
}
