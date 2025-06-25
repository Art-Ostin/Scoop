//
//  ProfileDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//

import SwiftUI

struct ProfileDetailsView: View {
    
    
    //All a Users Details:
    
    @State private var name: String = "Arthur"
    @State private var nationality: [String] = ["🇬🇧", "🇸🇪"]
    @State private var images: [String] = ["Image1", "Image2", "Image3", "Image4", "Image5", "Image6"]
    @State private var year = "U3"
    @State private var height = "193"
    @State private var passions: [String] = ["Astrophysics", "Cold Water Swimming", "Music Production", "Historical Geology"]
    @State private var hometown = "London"
    @State private var lookingFor = "Casual"
    @State private var Faculty = "Faculty of Arts"

    @State private var promptSelection1 = Prompts.instance["three words that"]
    @State private var promptSelection2 = Prompts.instance["on the date"]
    
    
    var body: some View {
            GeometryReader { geo in
                ZStack {
                    VStack{
                        topRow
                            .padding(.top, 8)
                        
                        Divider()
                            .padding(.leading)
                        
                        passionsRow(firstRow: true)
                        
                        Divider()
                            .padding(.leading)
                        
                        cityAndFaculty
                        
                        Divider()
                            .padding(.leading)
                        
                        passionsRow(firstRow: false)
                        
                        Divider()
                            .padding(.leading)
                        
                        TabView {
                            PromptResponseView(promptSelection: promptSelection1 ?? "Whatever", promptResponse: "Feeling the beauty of the facticity of life", inviteButton: true)
                                    .frame(maxHeight: .infinity, alignment: .top)
                                    
                            PromptResponseView(promptSelection: promptSelection2 ?? "Whatever", promptResponse: "Imagineing something incredible...being Alive", inviteButton: true)
                                .frame(maxHeight: .infinity, alignment: .top)
                            
                        }
                        .padding(.top)
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        .frame(width: geo.size.width, alignment: .leading)
                        
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.background)
                    .cornerRadius(30)
                    .font(.body(17))
                    
                }
            }
        }
    }


#Preview {
    ProfileDetailsView()
}



extension ProfileDetailsView {
    
    
    
    private var hDivider: some View {
        Rectangle()
            .frame(width: 1, height: 20)
            .foregroundStyle(Color(red: 0.86, green: 0.86, blue: 0.86))
        
    }
    
    private var cityAndFaculty: some View {
        HStack {
            
            HStack {
                Image("ScholarStyle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .padding(.leading)
                Text(Faculty)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .top)
            
            hDivider
            
            HStack {
                Image("House")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                
                Text(hometown)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.top)
        .padding(.bottom)
    }
    
    
    private var topRow: some View {
        HStack(spacing: 24){
            
            HStack{
                Image(systemName: "magnifyingglass")
                Text(lookingFor)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            hDivider
            HStack {
                Image(systemName: "graduationcap")
                Text(year)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            hDivider
            
            HStack {
                Image (systemName: "arrow.up.and.down")
                Text(height)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
        }
        .padding()
        
    }
    
    
    private func passionsRow(firstRow: Bool = true) -> some View {
        HStack {
            Image("HappyFace")
                .resizable()
                .frame(width: 20, height: 20)
            Text(firstRow ? firstThreePassions.joined(separator: ", ") : remainingPassions.joined(separator: ", "))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading)
        .padding(.top)
        .padding(.bottom)
    }
    
    private var firstThreePassions: [String] {
        Array(passions.prefix(2))
    }
    
    private var remainingPassions: [String] {
        Array(passions.dropFirst(2))
    }
}
