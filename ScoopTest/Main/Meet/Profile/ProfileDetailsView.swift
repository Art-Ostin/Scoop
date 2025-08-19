//
//  profileDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//

import SwiftUI

struct ProfileDetailsView: View {
    
    @Binding var vm: ProfileViewModel
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 36) {
            let p = vm.profileModel.profile
            
            Text(p.nationality?.joined(separator: "") ?? "")
            
            Text (p.hometown ?? "")
            
            Text(p.lookingFor ?? "")
            
            Text(p.year ?? "")
            
            Text(p.degree ?? "")
            
            Text(p.height ?? "")
            
            Text(p.interests?.joined(separator: ", ") ?? "")
            
            Text(p.attractedTo ?? "")
            
            Text(p.drinking ?? "")
            
            Text(p.marijuana ?? "")
            
            Text(p.smoking ?? "")
            
            Text(p.drugs ?? "")
            
            if let book = p.favouriteBook { Text(book) }
            
            if let movie = p.favouriteMovie { Text(movie) }
            
            if let song = p.favouriteSong { Text(song) }
            
            if let languages = p.languages { Text(languages)}
            
            if let prompt1 = p.prompt1 {
                PromptResponseView(vm: $vm, prompt: prompt1)
            }
            
            if let prompt2 = p.prompt2 {
                PromptResponseView(vm: $vm, prompt: prompt2)
            }
            
            if let prompt3 = p.prompt3 {
                PromptResponseView(vm: $vm, prompt: prompt3)
            }
        }
        .font(.body(17))
        .padding()
        .background(Color.white)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 0.05)
    }
}
