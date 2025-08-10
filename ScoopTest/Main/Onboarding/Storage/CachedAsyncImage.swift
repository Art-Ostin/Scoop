//
//  CachedAsyncImage.swift
//  ScoopTest
//
//  Created by Art Ostin on 31/07/2025.
//

import SwiftUI

struct CachedAsyncImage<Content: View>: View {
    @Environment(\.appDependencies) private var dependencies
    let url: URL
    @ViewBuilder let content: (Image) -> Content

    @State private var uiImage: UIImage?
    
    var body: some View {
        
        Group {
            if let uiImage {
                content(Image(uiImage: uiImage))
                    .onAppear { print("✅ rendered image from cache or network") }
            } else {
                ProgressView()
                    .task{
                        await load()
                    }
                    .onAppear { print("⏳ showing progress, starting load…") }

            }
        }
    }
    private func load() async {
//        uiImage = try? await dependencies.imageCache.fetchImage(for: url)
    }
}


// Takes the two Ids and saves to Cache upon Loading
//    func loadTwoDailyProfiles() async throws -> [UserProfile]? {
//        if getDailyProfileTimerEnd() != nil {
//            let ids = defaults.stringArray(forKey: Keys.twoDailyProfiles.rawValue) ?? []
//            return try await withThrowingTaskGroup(of: UserProfile.self, returning: [UserProfile].self) { group in
//                for id in ids {
//                    group.addTask { try await self.firestoreManager.getProfile(userId: id) }
//                }
//                var results: [UserProfile] = []
//                for try await profile in group {
//                    results.append(profile)
//                }
//                Task { await cacheManager.loadProfileImages(results)}
//                print("Loaded daily Profiles")
//                return results
//            }
//        } else {
//            print("Timer over, no profiles Loaded")
//            return nil
//        }
//    }
