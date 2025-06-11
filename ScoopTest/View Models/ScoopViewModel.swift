//
//  ScoopModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import Foundation
import SwiftUI

@Observable class ScoopViewModel {
    
    var stageIndex: Int = 0
    
    var sectionIndex: Int = 0
    
    var profileViewsStageIndex: Int = 0

    func nextPage()
    {
        withAnimation(.easeInOut(duration: 0.25)) {
            stageIndex += 1
        }
    }
    
    func nextProfileViewsStage()
    {
        profileViewsStageIndex += 1
    }
    
    
    
    
    
    var showOnboarding: Bool = false
    
    //MARK: Email Validation
    
    func EmailIsAuthorised(email: String) -> Bool {
        guard email.count > 4, let dotRange = email.range(of: ".") else {
            return false
        }
        
        let suffix = email[dotRange.upperBound...]
        return suffix.count >= 2
    }
    
    func nextSection()
    {
            sectionIndex += 1
    }
    
    
    
}

