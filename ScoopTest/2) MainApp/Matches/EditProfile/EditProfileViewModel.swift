//
//  EditProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/07/2025.
//

import Foundation
import PhotosUI


@Observable class EditProfileViewModel {
    
    let profileManager: ProfileManaging
    let storageManager: StorageManaging
    let userHandler: CurrentUserStore
    let user: UserProfile
    
    init (user: UserProfile, profile: ProfileManaging, storageManager: StorageManaging, userHandler: CurrentUserStore) {
        self.user = user
        self.profileManager = profile
        self.storageManager = storageManager
        self.userHandler = userHandler
    }
    
    
    //-------------------------
//    
//    
//    func updateSex(sex: String) {
//        Task {
//            try? await profileManager.updateSex(userId: user.userId, sex: sex)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func updateAttractedTo(attractedTo: String) {
//        Task {
//            try? await profileManager.updateAttractedTo(userId: user.userId, attractedTo: attractedTo)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    
//    func updateYear(year: String) {
//        Task {
//            try? await profileManager.updateYear(userId: user.userId, year: year)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func updateHeight(height: String) {
//        Task {
//            try? await profileManager.updateHeight(userId: user.userId, height: height)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func updateInterests(interests: String) {
//        Task {
//            try? await profileManager.updateInterests(userId: user.userId, interest: interests)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func removeInterests(interests: String) {
//        Task {
//            try? await profileManager.removeInterests(userId: user.userId, interest: interests)
//            try? await userHandler.loadUser()
//        }
//    }
//
//    func updateDegree(degree: String) {
//        Task {
//            try? await profileManager.updateDegree(userId: user.userId, degree: degree)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func updateHometown(hometown: String) {
//       Task {
//            try? await profileManager.updateHometown(userId: user.userId, hometown: hometown)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func updateName(name: String) {
//        Task {
//            try? await profileManager.updateName(userId: user.userId, name: name)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func updateNationality(nationality: String) {
//        Task {
//            try? await profileManager.updateNationality(userId: user.userId, nationality: nationality)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func removeNationality(nationality: String) {
//        Task {
//            try? await profileManager.removeNationality(userId: user.userId, nationality: nationality)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func updateLookingFor(lookingFor: String) {
//        Task {
//            try? await profileManager.updateLookingFor(userId: user.userId, lookingFor: lookingFor)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func updatePrompt(prompt: String, promptIndex: Int, response: String) {
//        let prompt = PromptResponse(prompt: prompt, response: response )
//        Task {
//            try? await profileManager.updatePrompt(userId: user.userId, promptIndex: promptIndex, prompt: prompt)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func updateDrinking(drinking: String) {
//        Task {
//            try? await profileManager.updateDrinking(userId: user.userId, drinking: drinking)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func updateSmoking(smoking: String) {
//        Task {
//            try? await profileManager.updateSmoking(userId: user.userId, smoking: smoking)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func updateMarijuana(marijuana: String) {
//        Task {
//            try? await profileManager.updateMarijuana(userId: user.userId, marijuana: marijuana)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func updateDrugs(drugs: String) {
//        Task {
//            try? await profileManager.updateDrugs(userId: user.userId, drugs: drugs)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func updateLanguages(languages: String) {
//        Task {
//            try? await profileManager.updateLanguages(userId: user.userId, languages: languages)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func updateFavouriteMovie(favouriteMovie: String) {
//        Task {
//            try? await profileManager.updateFavouriteMovie(userId: user.userId, favouriteMovie: favouriteMovie)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func updateFavouriteSong(favouriteSong: String) {
//        Task {
//            try? await profileManager.updateFavouriteSong(userId: user.userId, favouriteSong: favouriteSong)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    func updateFavouriteBook(favouriteBook: String) {
//        Task {
//            try? await profileManager.updateFavouriteBook(userId: user.userId, favouriteBook: favouriteBook)
//            try? await userHandler.loadUser()
//        }
//    }
//
//    
//    func updateCharacter(character: String) {
//        Task {
//            try? await profileManager.updateCharacter(userId: user.userId, character: character)
//            try? await userHandler.loadUser()
//        }
//    }
//    
//    
//    func removeCharacter(character: String) {
//        Task {
//            try? await profileManager.removeCharacter(userId: user.userId, character: character)
//            try? await userHandler.loadUser()
//        }
//    }
//    
}
