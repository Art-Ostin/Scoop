//
//  profileDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//

import SwiftUI

struct ProfileDetailsView: View {
    
//    @Binding var vm: ProfileViewModel
    
    var body: some View {
            VStack(spacing: 60) {
                
                keyInfo
                
                homeAndDegree
                
                PromptView(prompt: PromptResponse(prompt: "What is the best date", response: "A girl who I never saw again.. in the same light"))
                
                
                ViewInterests(passions: ["Golf", "Badmington", "Djing", "Cold Swimming", "Football"])
                
                
                PromptView(prompt: PromptResponse(prompt: "What is the best date", response: "A girl who I never saw again.. in the same light"))
            }
            .padding(36)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 30)
                    .inset(by: 0.5)
                    .stroke(Color.grayPlaceholder, lineWidth: 1)
            }
            .background (
                RoundedRectangle(cornerRadius: 30)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
                    .ignoresSafeArea(edges: .bottom)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .inset(by: 0.5)
                    .stroke(Color.grayPlaceholder, lineWidth: 1)
            )
            .padding(.horizontal, 6)
        
        }
    }

#Preview {
    ProfileDetailsView()
}


extension ProfileDetailsView {
    
    private var keyInfo: some View {
        HStack (spacing: 0)  {
            InfoItem(image: "magnifyingglass", info: "Casual")
            
            Spacer()
            
            InfoItem(image: "Year", info: "U3")
            
            Spacer()
            
            InfoItem(image: "Height", info: "193" + "cm")
        }
    }
    
    
    private var homeAndDegree: some View {
        
        HStack(spacing: 0) {
            
            InfoItem(image: "House", info: "London")
            
            Spacer()
            
            InfoItem(image: "ScholarStyle", info: "Politics")
            
        }
    }
    
    private var vicesView: some View {
        HStack(spacing: 0) {
            InfoItem(image: "DrinkingIcon", info: "Yes")
            
            Spacer()
            
            InfoItem(image: "SmokingIcon", info: "Yes")
            
            Spacer()
            
            InfoItem(image: "WeedIcon", info: "Yes")
            
            Spacer()
            
            InfoItem(image: "DrugsIcon", info: "Yes")
            
        }
    }
}
    

struct PromptView: View {
    
    let prompt: PromptResponse
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 24) {
            Text(prompt.prompt)
                .font(.body(14, .italic))
            
            Text(prompt.response)
                .font(.title(20))
                .lineSpacing(8)
        }
        .padding(.horizontal, -1)
    }
}


struct ViewInterests: View {
    
    var passions: [String]
        
    private var rows: [[String]] {
        stride(from: 0, to: passions.count, by: 2).map {
            Array(passions[$0..<min($0+2, passions.count)])
        }
    }
        
    var body: some View {
        
        VStack {
            HStack(spacing: 12) {
                Image("HappyFace")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 17)
                
                Text("Passions")
                    .font(.body(15, .regular))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            
            VStack(spacing: 24) {
                ForEach(rows.indices, id: \.self) { index in
                    let row = rows[index]
                    HStack {
                        Text(row[safe: 0] ?? "")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(row.count > 1 ? row[1] : "")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .font(.body())
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
            )
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.88, green: 0.88, blue: 0.88), lineWidth: 0.5))
            
        }
    }
}




struct InfoItem: View {
    
    let image: String
    let info: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(height: 17)
            
            Text(info)
                .font(.body(17, .medium))
            
        }
    }
}


    
    /*
     Text (p.hometown)
     
     Text(p.lookingFor)
     
     Text(p.year)
     
     Text(p.degree)
     
     Text(p.height)
     
     Text(p.interests.joined(separator: ", "))
     
     Text(p.attractedTo)
     
     Text(p.drinking)
     
     Text(p.marijuana)
     
     Text(p.smoking)
     
     Text(p.drugs)
     
     if let book = p.favouriteBook { Text(book) }
     
     if let movie = p.favouriteMovie { Text(movie) }
     
     if let song = p.favouriteSong { Text(song) }
     
     if !p.languages.isEmpty { Text("Languages:") }
     
     if let prompt1 = p.prompt1 {
     PromptResponseView(vm: $vm, prompt: prompt1)
     }
     
     if let prompt2 = p.prompt2 {
     PromptResponseView(vm: $vm, prompt: prompt2)
     }
     
     if let prompt3 = p.prompt3 {
     PromptResponseView(vm: $vm, prompt: prompt3)
     }
     */
    /*
     GeometryReader { geo in
         let size = geo.size.width - 12
         VStack(alignment: .leading, spacing: 36) {
             
             let p = vm.profileModel.profile
             
             VStack(spacing: 32) {
                 ForEach(0..<10) { _ in
                     Text( "hello world")
                 }
             }
         }
         .frame(width: size)
         .padding(.horizontal, 12)
         .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
         .font(.body(17))
         .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 0.05)
     }
 }
     
     */
    
    
