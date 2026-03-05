//
//  ChatView.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI
import UIKit


struct ChatContainer: View {
    
        
    @Bindable var vm: ChatViewModel
    @Bindable var eventVM: EventViewModel
    
    @State var selectedProfile: ProfileModel? = nil
    @State var dismissOffset: CGFloat? = nil
    @State var profileImages: [UIImage] = []
    @State var text = ""
    
    @Namespace private var ns
    
    @FocusState private var isFocused
    
    
    var isEvent = false
    let profileModel: ProfileModel
    
    
    var body: some View {
        ZStack {
            messageView
            
            if let profile = selectedProfile {
                profileView(profile: profile)
            }
        }
        .overlay(alignment: .top) {chatHeaderView}
        .task {
            let loadImages = await vm.loadImages(profileModel: profileModel)
            profileImages = loadImages
        }
    }
}

//Other Views
extension ChatContainer {
    
    private func profileView(profile: ProfileModel) -> some View {
        ProfileView(vm:
                    ProfileViewModel(defaults: eventVM.defaults,
                            sessionManager: eventVM.sessionManager,
                            profileModel: profile,
                            imageLoader: eventVM.imageLoader),
                    profileImages: profileImages,
                    selectedProfile: $selectedProfile,
                    dismissOffset: $dismissOffset, isMessageProfile: true)
        .id(profileModel.profile.id)
        .zIndex(1)
        .transition(.move(edge: .bottom))
    }
    
    
}
