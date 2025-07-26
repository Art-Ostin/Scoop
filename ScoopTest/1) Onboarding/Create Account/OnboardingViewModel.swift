//
//  OnboardingViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/07/2025.
//

import Foundation
import SwiftUI


@Observable class OnboardingViewModel {
    
    //Logic for User Email & veryifying Email
    
    // Logic for tracking which Screen the User is on
    var screen: Int = 0
    
    let transition: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    let transition2: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .identity)
    let transition3: AnyTransition = .asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .leading))
    
    
    // Logic to Create & Sign the User in
    func createUser (email: String, password: String) async throws {
      try await AuthenticationManager.instance.createUser(email: email, password: password)
    }
    func signInUser(email: String, password: String) async throws {
       try await AuthenticationManager.instance.signInUser(email: email, password: password)
    }
    
}
