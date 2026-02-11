//
//  ProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/08/2025.
//
import Foundation
import SwiftUI


enum ProfileViewType {
    case invite, accept, view
}

@MainActor
@Observable class ProfileViewModel {
    
    let profileModel: ProfileModel
    let imageLoader: ImageLoading
    
    let defaults: DefaultsManaging
    
    var receivedEvent: UserEvent? { profileModel.event }
    
    var viewProfileType: ProfileViewType
    
    init(defaults: DefaultsManaging, profileModel: ProfileModel, imageLoader: ImageLoading) {
        self.profileModel = profileModel
        self.imageLoader = imageLoader
        self.defaults = defaults
        
        if profileModel.event?.status == .pastAccepted || profileModel.event?.status == .accepted {
            self.viewProfileType = .view
        } else if profileModel.event?.status == .pending {
            self.viewProfileType = .accept
        } else {
            self.viewProfileType = .invite
        }
    }
    
    func loadImages() async -> [UIImage] {
        return await imageLoader.loadProfileImages([profileModel.profile])
    }
}
enum DragType {
    case details, profile, horizontal
}


@Observable final class ProfileUIState {
    var showInvitePopup = false
    var showDeclineScreen = false
    var detailsOpen = false
    var dragType: DragType? = nil
    var isTopOfScroll = true
    var detailsOpenOffset: CGFloat = -284
    var hideProfileScreen: Bool = false
    let dismissalDuration: TimeInterval = 0.35
}




/*
 */

