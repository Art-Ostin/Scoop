//
//  EditProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/07/2025.
//

import Foundation
import FirebaseAuth
import PhotosUI



@Observable class EditProfileViewModel {
    
    static let instance = EditProfileViewModel()
    
    private init () {}
    
    private(set) var user: UserProfile? = nil
        
    
    func loadUser() async throws {
        let AuthUser = try AuthenticationManager.instance.getAuthenticatedUser()
        let profile = try await ProfileManager.instance.getProfile(userId: AuthUser.uid)
        await MainActor.run {
            self.user = profile
        }
    }
    
    
    func updateSex(sex: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateSex(userId: user.userId, sex: sex)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func updateAttractedTo(attractedTo: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateAttractedTo(userId: user.userId, attractedTo: attractedTo)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func updateYear(year: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateYear(userId: user.userId, year: year)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func updateHeight(height: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateHeight(userId: user.userId, height: height)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func updateInterests(interests: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateInterests(userId: user.userId, interest: interests)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func removeInterests(interests: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.removeInterests(userId: user.userId, interest: interests)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }

    func updateDegree(degree: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateDegree(userId: user.userId, degree: degree)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func updateHometown(hometown: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateHometown(userId: user.userId, hometown: hometown)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func updateName(name: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateName(userId: user.userId, name: name)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func updateNationality(nationality: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateNationality(userId: user.userId, nationality: nationality)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func removeNationality(nationality: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.removeNationality(userId: user.userId, nationality: nationality)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func updateLookingFor(lookingFor: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateLookingFor(userId: user.userId, lookingFor: lookingFor)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func updatePrompt(prompt: String, promptIndex: Int, response: String) {
        guard let user else {return}
        let prompt = PromptResponse(prompt: prompt, response: response )
        Task {
            try? await ProfileManager.instance.updatePrompt(userId: user.userId, promptIndex: promptIndex, prompt: prompt)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    
    func updateDrinking(drinking: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateDrinking(userId: user.userId, drinking: drinking)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func updateSmoking(smoking: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateSmoking(userId: user.userId, smoking: smoking)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func updateMarijuana(marijuana: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateMarijuana(userId: user.userId, marijuana: marijuana)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func updateDrugs(drugs: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateDrugs(userId: user.userId, drugs: drugs)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func updateLanguages(languages: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateLanguages(userId: user.userId, languages: languages)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func updateFavouriteMovie(favouriteMovie: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateFavouriteMovie(userId: user.userId, favouriteMovie: favouriteMovie)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func updateFavouriteSong(favouriteSong: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateFavouriteSong(userId: user.userId, favouriteSong: favouriteSong)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func updateFavouriteBook(favouriteBook: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateFavouriteBook(userId: user.userId, favouriteBook: favouriteBook)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }

    
    func updateCharacter(character: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateCharacter(userId: user.userId, character: character)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
    func removeCharacter(character: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.removeCharacter(userId: user.userId, character: character)
            let updated = try? await ProfileManager.instance.getProfile(userId: user.userId)
            await MainActor.run {
                self.user = updated
            }
        }
    }
    
}
