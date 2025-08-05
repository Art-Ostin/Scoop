//
//  EventViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/08/2025.
//

import Foundation


@Observable class EventViewModel {
    
    var dependencies: AppDependencies

    var showEvent: Bool = false
    
    
    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

   var events: [(event: Event, user: UserProfile)] = []
    
    
    var currentEvent: Event?
    var currentUser: UserProfile?
    
    var showEventDetails: Bool = false
    
    var selection: Int? = nil
    
    var showProfile: Bool = false

    
    
    
    
}
