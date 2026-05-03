//
//  UserSessionManager.swift
//  Scoop
//
//  Created by Art Ostin on 02/05/2026.
//

import SwiftUI

//Logic dealing with what part of app to show to user and when, and User's Status
extension SessionManager {
    
    //Tracks if user signed in or not & decides app state on launch
    func userStream() {        
        setAuthStream(Task { @MainActor [weak self] in
            guard let self else { return }
            for await uid in self.authService.authStateStream() {
                //1. Get User ID, if not go to Login Screen (Also triggered when user logs out) 
                guard let uid else { self.goToLoginScreen() ; continue }

                //2.Get user Profile, if none go to onboarding screen
                guard let user = await self.fetchUser(uid) else { self.goToOnboarding() ; continue }

                //3.If fetched user's profile, start session with user
                startSession(user: user)
            }
        })
    }
    
    private func fetchUser(_ id: String) async -> UserProfile? {
        return try? await userRepo.fetchProfile(userId: id)
    }
    
    private func goToOnboarding() {
        stopSession()
        appState = .createAccount
    }
    
    private func goToLoginScreen() {
        appState = .login
        stopSession()
        defaultsManager.deleteDefaults()
    }

    //Not private as need it to sign up
    func startSession(user: UserProfile) {
        //1. Start new session, inputting a user
        stopSession()
        setSessionUser(user)

        //2. Start the streams with initial snapshots
        userProfileStream()
        profilesStream()
        eventsStream()
        recentChatStream()

        subscribeImageLoad(for: user)
    }
    

    //Not private as need it when sign out
    func stopSession() {
        cancelAllStreams()
        recentMessageReceived = nil
        activeChatEventId = nil
        setSessionUser(nil)
    }

    //Checks if user is blocked or frozen before going to main appState
    func openMainApp(for user: UserProfile) {
        if user.isBlocked || user.frozenUntil != nil {
            appState = .frozen
        } else {
            appState = .app
        }
    }

    //Listen to user's profile in case there is an update on their account, and updates the User
    private func userProfileStream() {
        subscribe("userProfile", to: userRepo.userListener(userId: user.id)) { [weak self] change in
            guard let self, let change else { return }
            setSessionUser(change)
            if profilesHaveLoaded {
                openMainApp(for: change)
            }
        }
    }
}
