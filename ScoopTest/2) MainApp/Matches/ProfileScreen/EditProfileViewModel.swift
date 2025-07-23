//
//  EditProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/07/2025.
//

import Foundation
import FirebaseAuth
import PhotosUI


@MainActor
@Observable class EditProfileViewModel {
    
    static let instance = EditProfileViewModel()
    
    private init () {}
    
    var nameTextField: String = "Arthur"
    var hometownTextField: String = "London"
    var degreeTextField: String = "Politics"
    
    private(set) var user: UserProfile? = nil
        
    
    func loadUser() async throws {
        let AuthUser = try AuthenticationManager.instance.getAuthenticatedUser()
        self.user = try await ProfileManager.instance.getProfile(userId: AuthUser.uid)
    }
    
    func updateSex(sex: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateSex(userId: user.userId, sex: sex)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func updateAttractedTo(attractedTo: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateAttractedTo(userId: user.userId, attractedTo: attractedTo)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func updateYear(year: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateYear(userId: user.userId, year: year)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func updateHeight(height: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateHeight(userId: user.userId, height: height)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func updateInterests(interests: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateInterests(userId: user.userId, interest: interests)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func removeInterests(interests: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.removeInterests(userId: user.userId, interest: interests)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }

    
    func updateDegree(degree: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateDegree(userId: user.userId, degree: degree)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func updateHometown(hometown: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateHometown(userId: user.userId, hometown: hometown)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func updateName(name: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateName(userId: user.userId, name: name)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func updateNationality(nationality: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateNationality(userId: user.userId, nationality: nationality)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func removeNationality(nationality: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.removeNationality(userId: user.userId, nationality: nationality)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func updateLookingFor(lookingFor: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateLookingFor(userId: user.userId, lookingFor: lookingFor)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func updatePrompt(prompt: String, promptIndex: Int, response: String) {
        guard let user else {return}
        let prompt = PromptResponse(prompt: prompt, response: response )
        Task {
            try? await ProfileManager.instance.updatePrompt(userId: user.userId, promptIndex: promptIndex, prompt: prompt)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    
    func updateDrinking(drinking: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateDrinking(userId: user.userId, drinking: drinking)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func updateSmoking(smoking: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateSmoking(userId: user.userId, smoking: smoking)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func updateMarijuana(marijuana: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateMarijuana(userId: user.userId, marijuana: marijuana)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func updateDrugs(drugs: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateDrugs(userId: user.userId, drugs: drugs)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func updateLanguages(languages: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateLanguages(userId: user.userId, languages: languages)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    
    func updateFavouriteMovie(favouriteMovie: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateFavouriteMovie(userId: user.userId, favouriteMovie: favouriteMovie)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func updateFavouriteSong(favouriteSong: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateFavouriteSong(userId: user.userId, favouriteSong: favouriteSong)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func updateFavouriteBook(favouriteBook: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateFavouriteBook(userId: user.userId, favouriteBook: favouriteBook)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }

    
    func updateCharacter(character: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateCharacter(userId: user.userId, character: character)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
    func removeCharacter(character: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.removeCharacter(userId: user.userId, character: character)
            self.user = try? await ProfileManager.instance.getProfile(userId: user.userId)
        }
    }
    
}
