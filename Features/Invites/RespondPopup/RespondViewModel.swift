//
//  RespondViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 23/03/2026.
//

import SwiftUI

@Observable
class RespondViewModel {
    
    let image: UIImage
    
    var respondDraft: RespondDraft {
        didSet {updateDefaults()}
    }
    
    init(respondDraft: RespondDraft, profileImage: UIImage) {
        self.respondDraft = respondDraft
        self.image = profileImage
    }
    
    
    func updateDraftTime() {
        
    }
    
    
    
    func onAccept() {
        
    }
    
    func onDecline() {
        
    }
    
    private func updateDefaults() {
        
    }
}
