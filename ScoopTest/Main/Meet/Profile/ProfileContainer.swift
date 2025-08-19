
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
                if vm.showInvite {
                    let image = vm.firstImage ?? UIImage()
                    Rectangle()
                        .fill(.thinMaterial)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { vm.showInvite = false }
                    if let event = vm.event {
                        AcceptInvitePopup(vm: SendInviteViewModel(eventManager: dep.eventManager, cycleManager: dep.cycleManager, recipient: vm.p), image: image) {
                            onDismiss()
                        }
                    } else {
                        SendInvitePopup(vm: SendInviteViewModel(eventManager: dep.eventManager, cycleManager: dep.cycleManager, recipient: vm.p), image: image) {
                            onDismiss()
                        }
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
                    onDismiss()
                }
        }
    }
}
