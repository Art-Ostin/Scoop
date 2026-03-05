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
    
    @State var profileOpen: ProfileModel? = nil
    @State var dismissOffset: CGFloat? = nil
    @State var profileImages: [UIImage] = []
    
    @FocusState private var isFocused
    
    var isEvent = false
    let profileModel: ProfileModel
    
    var body: some View {
        ZStack {
            ChatScrollView(vm: vm, isFocused: $isFocused)
            if profileOpen != nil {
                profileView
            }
        }
        .overlay(alignment: .top) {
            ChatHeaderBar(profileOpen: $profileOpen, dismissOffset: $dismissOffset, profileModel: profileModel, isEvent: isEvent, isFocused: $isFocused)
        }
        .task { profileImages = await eventVM.loadImages(profileModel: profileModel)}
    }
}

//Other Views
extension ChatContainer {
    
    private var profileView: some View {
        ProfileView(vm:
                    ProfileViewModel(defaults: eventVM.defaults,
                            sessionManager: eventVM.sessionManager,
                            profileModel: profileModel,
                            imageLoader: eventVM.imageLoader),
                    profileImages: profileImages,
                    selectedProfile: $profileOpen,
                    dismissOffset: $dismissOffset, isMessageProfile: true)
        .id(profileModel.profile.id)
        .zIndex(1)
        .transition(.move(edge: .bottom))
    }
    
    
}
