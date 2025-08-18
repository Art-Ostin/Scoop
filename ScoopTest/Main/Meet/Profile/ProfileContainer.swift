
import Foundation
import SwiftUI

struct ProfileView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appDependencies) private var dep
    
    @State private var vm: ProfileViewModel
    @State var image: UIImage?
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
                    Rectangle()
                        .fill(.thinMaterial)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            vm.showInvite = false
                        }
                    if let event = vm.event {
                        ZStack {
                            AcceptInvitePopup(vm: $vm, image: $image, event: event) {
                                onDismiss()
                            }
                        }
                    } else  {
                        SendInvitePopup(recipient: vm.p, profileVM: $vm, image: $image) {
                            onDismiss()
                        }
                    }
                }
            }
            .task {
                image = await vm.loadImages().first
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
                    dismiss()
                }
        }
    }
}



//    init(profile: UserProfile, event: UserEvent? = nil, onDismiss: @escaping () -> Void = {}) {
//        self._vm = State(initialValue: ProfileViewModel(profile: profile, profileType: .sendInvite, event: event, cacheManager: dep.cacheManager))
//        self.onDismiss = onDismiss
//    }
