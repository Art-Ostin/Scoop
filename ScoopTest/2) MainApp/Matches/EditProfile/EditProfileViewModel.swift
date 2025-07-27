//
//  EditProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/07/2025.
//

import Foundation
import PhotosUI


@Observable class EditProfileViewModel {
    
    let currentUser: CurrentUserStore
    let profileManager: ProfileManaging
    
    init (currentUser: CurrentUserStore, profile: ProfileManaging) {
        self.currentUser = currentUser
        self.profileManager = profile
    }
    
    
    
    
    func updateSex(sex: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateSex(userId: user.userId, sex: sex)
            try? await currentUser.loadUser()
        }
    }
    
    func updateAttractedTo(attractedTo: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateAttractedTo(userId: user.userId, attractedTo: attractedTo)
            try? await currentUser.loadUser()
        }
    }
    
    func updateYear(year: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateYear(userId: user.userId, year: year)
            try? await currentUser.loadUser()
        }
    }
    
    func updateHeight(height: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateHeight(userId: user.userId, height: height)
            try? await currentUser.loadUser()
        }
    }
    
    func updateInterests(interests: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateInterests(userId: user.userId, interest: interests)
            try? await currentUser.loadUser()
        }
    }
    
    func removeInterests(interests: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.removeInterests(userId: user.userId, interest: interests)
            try? await currentUser.loadUser()
        }
    }

    func updateDegree(degree: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateDegree(userId: user.userId, degree: degree)
            try? await currentUser.loadUser()
        }
    }
    
    func updateHometown(hometown: String) {
        guard let user = currentUser.user else {return}
       Task {
            try? await profileManager.updateHometown(userId: user.userId, hometown: hometown)
            try? await currentUser.loadUser()
        }
    }
    
    func updateName(name: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateName(userId: user.userId, name: name)
            try? await currentUser.loadUser()
        }
    }
    
    func updateNationality(nationality: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateNationality(userId: user.userId, nationality: nationality)
            try? await currentUser.loadUser()
        }
    }
    
    func removeNationality(nationality: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.removeNationality(userId: user.userId, nationality: nationality)
            try? await currentUser.loadUser()
        }
    }
    
    func updateLookingFor(lookingFor: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateLookingFor(userId: user.userId, lookingFor: lookingFor)
            try? await currentUser.loadUser()
        }
    }
    
    func updatePrompt(prompt: String, promptIndex: Int, response: String) {
        guard let user = currentUser.user else {return}
        let prompt = PromptResponse(prompt: prompt, response: response )
        Task {
            try? await profileManager.updatePrompt(userId: user.userId, promptIndex: promptIndex, prompt: prompt)
            try? await currentUser.loadUser()
        }
    }
    
    func updateDrinking(drinking: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateDrinking(userId: user.userId, drinking: drinking)
            try? await currentUser.loadUser()
        }
    }
    
    func updateSmoking(smoking: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateSmoking(userId: user.userId, smoking: smoking)
            try? await currentUser.loadUser()
        }
    }
    
    func updateMarijuana(marijuana: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateMarijuana(userId: user.userId, marijuana: marijuana)
            try? await currentUser.loadUser()
        }
    }
    
    func updateDrugs(drugs: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateDrugs(userId: user.userId, drugs: drugs)
            try? await currentUser.loadUser()
        }
    }
    
    func updateLanguages(languages: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateLanguages(userId: user.userId, languages: languages)
            try? await currentUser.loadUser()
        }
    }
    
    func updateFavouriteMovie(favouriteMovie: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateFavouriteMovie(userId: user.userId, favouriteMovie: favouriteMovie)
            try? await currentUser.loadUser()
        }
    }
    
    func updateFavouriteSong(favouriteSong: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateFavouriteSong(userId: user.userId, favouriteSong: favouriteSong)
            try? await currentUser.loadUser()
        }
    }
    
    func updateFavouriteBook(favouriteBook: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateFavouriteBook(userId: user.userId, favouriteBook: favouriteBook)
            try? await currentUser.loadUser()
        }
    }

    
    func updateCharacter(character: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.updateCharacter(userId: user.userId, character: character)
            try? await currentUser.loadUser()
        }
    }
    
    
    func removeCharacter(character: String) {
        guard let user = currentUser.user else {return}
        Task {
            try? await profileManager.removeCharacter(userId: user.userId, character: character)
            try? await currentUser.loadUser()
        }
    }
    
}
