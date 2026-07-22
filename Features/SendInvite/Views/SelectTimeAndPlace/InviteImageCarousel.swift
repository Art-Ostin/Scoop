//
//  InviteImageCarousel.swift
//  Scoop
//
//  Created by Art Ostin on 07/07/2026.
//

import SwiftUI

struct InviteImageCarousel: View {
    //Injected
    let images: [UIImage]
    let name: String
    let details: String
    let expanded: Bool
    
    @Binding var confirmInviteScreen: Bool
    let coverImage: UIImage? //Close-from-page-N: the page flying home, over the snapped-to page 0 (see SendInviteCard.prepareClose)
    let vm: TimeAndPlaceViewModel //@Observable class — drives the options menu (clear draft)
    let declineProfile: () -> Void
    var pagingDisabled: Bool = false //Locked while the frame animates or a swipe-dismiss owns the touch
    var showsCollapsedChrome: Bool = true //The collapsed ProfileCard look (name/details caption + button replica). Off when the source is a plain image (profile hero).

    
    @State private var inviteButtonPopped = false
    @State private var showInfoScreen = false //"How Invites Work" sheet, opened from the options menu

    static let imageSpace = "InviteImageCarousel.image"
    

    var body: some View {
        ImageCarouselInvite(
            images: images,
            aspectRatio: confirmInviteScreen ? .confirmInviteImage : .invitedImage,
            confirmScreen: confirmInviteScreen
        )
        .scrollDisabled(images.count <= 1 || pagingDisabled)
        .animation(.transition, value: confirmInviteScreen)
        .coordinateSpace(name: Self.imageSpace)
        
        
        
        
        
        
        
        .modifier(InviteImageOverlays(vm: <#T##TimeAndPlaceViewModel#>, scrollProgress: <#T##Double#>, name: <#T##String#>, expanded: <#T##Bool#>, showCollapsedChrome: <#T##Bool#>, details: <#T##String#>, coverImage: <#T##UIImage?#>, images: <#T##[UIImage]#>, confirmScreen: <#T##Binding<Bool>#>, showInfoScreen: <#T##Binding<Bool>#>, inviteButtonPopped: <#T##Binding<Bool>#>, declineProfile: <#T##() -> Void#>))
        
    }
}


