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
            
            Text(vm.p.nationality?.joined(separator: "") ?? "")
            
            Text (vm.p.hometown ?? "")
            
            Text(vm.p.lookingFor ?? "")
            
            Text(vm.p.year ?? "")
            
            Text(vm.p.degree ?? "")
            
            Text(vm.p.height ?? "")
            
            Text(vm.p.interests?.joined(separator: ", ") ?? "")
            
            Text(vm.p.attractedTo ?? "")
            
            Text(vm.p.drinking ?? "")
            
            Text(vm.p.marijuana ?? "")
            
            Text(vm.p.smoking ?? "")
            
            Text(vm.p.drugs ?? "")
            
            if let book = vm.p.favouriteBook { Text(book) }
            
            if let movie = vm.p.favouriteMovie { Text(movie) }
            
            if let song = vm.p.favouriteSong { Text(song) }
            
            if let languages = vm.p.languages { Text(languages)}
            
            if let prompt1 = vm.p.prompt1 {
                PromptResponseView(vm: $vm, prompt: prompt1)
            }
            
            if let prompt2 = vm.p.prompt2 {
                PromptResponseView(vm: $vm, prompt: prompt2)
            }
            
            if let prompt3 = vm.p.prompt3 {
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
