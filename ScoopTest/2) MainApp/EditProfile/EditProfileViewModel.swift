//
//  EditProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/07/2025.
//

import Foundation
import PhotosUI


@Observable class EditProfileViewModel {
    
    static let instance = EditProfileViewModel()
    
    private init () {}

    private let userStore = CurrentUserStore.shared

    var user: UserProfile? { userStore.user }
    
    func updateSex(sex: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateSex(userId: user.userId, sex: sex)
            try? await userStore.loadUser()
        }
    }
    
    func updateAttractedTo(attractedTo: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateAttractedTo(userId: user.userId, attractedTo: attractedTo)
            try? await userStore.loadUser()
        }
    }
    
    func updateYear(year: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateYear(userId: user.userId, year: year)
            try? await userStore.loadUser()
        }
    }
    
    func updateHeight(height: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateHeight(userId: user.userId, height: height)
            try? await userStore.loadUser()
        }
    }
    
    func updateInterests(interests: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateInterests(userId: user.userId, interest: interests)
            try? await userStore.loadUser()
        }
    }
    
    func removeInterests(interests: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.removeInterests(userId: user.userId, interest: interests)
            try? await userStore.loadUser()
        }
    }

    func updateDegree(degree: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateDegree(userId: user.userId, degree: degree)
            try? await userStore.loadUser()
        }
    }
    
    func updateHometown(hometown: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateHometown(userId: user.userId, hometown: hometown)
            try? await userStore.loadUser()
        }
    }
    
    func updateName(name: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateName(userId: user.userId, name: name)
            try? await userStore.loadUser()
        }
    }
    
    func updateNationality(nationality: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateNationality(userId: user.userId, nationality: nationality)
            try? await userStore.loadUser()
        }
    }
    
    func removeNationality(nationality: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.removeNationality(userId: user.userId, nationality: nationality)
            try? await userStore.loadUser()
        }
    }
    
    func updateLookingFor(lookingFor: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateLookingFor(userId: user.userId, lookingFor: lookingFor)
            try? await userStore.loadUser()
        }
    }
    
    func updatePrompt(prompt: String, promptIndex: Int, response: String) {
        guard let user else {return}
        let prompt = PromptResponse(prompt: prompt, response: response )
        Task {
            try? await ProfileManager.instance.updatePrompt(userId: user.userId, promptIndex: promptIndex, prompt: prompt)
            try? await userStore.loadUser()
        }
    }
    
    
    func updateDrinking(drinking: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateDrinking(userId: user.userId, drinking: drinking)
            try? await userStore.loadUser()
        }
    }
    
    func updateSmoking(smoking: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateSmoking(userId: user.userId, smoking: smoking)
            try? await userStore.loadUser()
        }
    }
    
    func updateMarijuana(marijuana: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateMarijuana(userId: user.userId, marijuana: marijuana)
            try? await userStore.loadUser()
        }
    }
    
    func updateDrugs(drugs: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateDrugs(userId: user.userId, drugs: drugs)
            try? await userStore.loadUser()
        }
    }
    
    func updateLanguages(languages: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateLanguages(userId: user.userId, languages: languages)
            try? await userStore.loadUser()
        }
    }
    
    func updateFavouriteMovie(favouriteMovie: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateFavouriteMovie(userId: user.userId, favouriteMovie: favouriteMovie)
            try? await userStore.loadUser()
        }
    }
    
    func updateFavouriteSong(favouriteSong: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateFavouriteSong(userId: user.userId, favouriteSong: favouriteSong)
            try? await userStore.loadUser()
        }
    }
    
    func updateFavouriteBook(favouriteBook: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateFavouriteBook(userId: user.userId, favouriteBook: favouriteBook)
            try? await userStore.loadUser()
        }
    }

    
    func updateCharacter(character: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.updateCharacter(userId: user.userId, character: character)
            try? await userStore.loadUser()
        }
    }
    
    
    func removeCharacter(character: String) {
        guard let user else {return}
        Task {
            try? await ProfileManager.instance.removeCharacter(userId: user.userId, character: character)
            try? await userStore.loadUser()
        }
    }
    
}
