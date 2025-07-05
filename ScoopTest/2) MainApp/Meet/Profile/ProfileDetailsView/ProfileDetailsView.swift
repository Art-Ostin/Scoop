//
//  ProfileDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//

import SwiftUI

struct ProfileDetailsView: View {
    
    @Bindable var vm: ProfileViewModel
            
    
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
                            PromptResponseView(vm: vm, inviteButton: true)
                                    .frame(maxHeight: .infinity, alignment: .top)
                                    
                            PromptResponseView(vm: vm, inviteButton: true)
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
    ProfileDetailsView(vm: ProfileViewModel())
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
                Text(vm.profile.faculty)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .top)
            
            hDivider
            
            HStack {
                Image("House")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                
                Text(vm.profile.hometown)
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
                Text(vm.profile.lookingFor)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            hDivider
            HStack {
                Image(systemName: "graduationcap")
                Text(vm.profile.year)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            hDivider
            
            HStack {
                Image (systemName: "arrow.up.and.down")
                Text(vm.profile.height)
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
        Array(vm.profile.passions.prefix(2))
    }
    
    private var remainingPassions: [String] {
        Array(vm.profile.passions.dropFirst(2))
    }
}
