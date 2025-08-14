
import Foundation
import SwiftUI


struct ProfileView: View {
        
    @Environment(\.dismiss) private var dismiss
    @State private var vm: ProfileViewModel
    
    let onDismiss: () -> Void

    @State var image: UIImage?
    
    
    init(profile: UserProfile, showInviteButton: Bool = false, dep: AppDependencies, event: UserEvent? = nil, onDismiss: @escaping () -> Void = {}) {
        self._vm = State(initialValue: ProfileViewModel(profile: profile, showInvite: showInviteButton, dep: dep, profileType: .sendInvite, event: event))
        self.onDismiss = onDismiss
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
                            if let image {
                                PopUpView(image: image, event: event, vm: vm)
                            }
                        } else {
                            SendInviteView(recipient: vm.p, dep: vm.dep, profileVM: $vm)
                        }
                    }
                }
            }
            .task {
                image = await vm.dep.cacheManager.loadProfileImages([vm.p]).first
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
