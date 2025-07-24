//
//  ProfileDetailsViewInfo.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.
//

import SwiftUI

struct ProfileDetailsViewInfo: View {
    
    @Binding var vm: ProfileViewModel
    
    private var profile: localProfile{vm.profile}
    
    var body: some View {
        
        
        
        VStack {
            
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
        }
    }
}

#Preview {
    ProfileDetailsViewInfo(vm: .constant(ProfileViewModel()))
}

extension ProfileDetailsViewInfo {
    
    
    private var topRow: some View {
        
        
        if let profile = vm.profile {
            
            HStack(spacing: 24){
                
                HStack{
                    Image(systemName: "magnifyingglass")
                    Text(profile.lookingFor ?? "")
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                hDivider
                
                HStack {
                    Image(systemName: "graduationcap")
                    Text(profile.year ?? "")
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                hDivider
                
                HStack {
                    Image (systemName: "arrow.up.and.down")
                    Text(profile.height ?? "")
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
            }
            .padding()
        }
    }
    
    
    private func passionsRow(firstRow: Bool = true) -> some View {
        
        
        if let interests = vm.profile?.interests {
            HStack {
                Image("HappyFace")
                    .resizable()
                    .frame(width: 20, height: 20)
                Text(firstRow ? interests.prefix(2).joined(separator: ", ") : interests.dropFirst(2).joined(separator: ", "))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading)
            .padding(.top)
            .padding(.bottom)
        }
    }
    
    
    private var cityAndFaculty: some View {
        
        
        if let degree  = vm.profile?.degree {
            HStack {
                HStack {
                    Image("ScholarStyle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(.leading)
                    Text(degree)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .top)
        }
    
            
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
    
    private var hDivider: some View {
        Rectangle()
            .frame(width: 1, height: 20)
            .foregroundStyle(Color(red: 0.86, green: 0.86, blue: 0.86))
        
    }
}



struct HDivider: View {
    
    var body: some View {
        
        Rectangle()
            .frame(width: 1, height: 20)
            .foregroundStyle(Color(red: 0.86, green: 0.86, blue: 0.86))
    }
    
}
