//
//  ProfileImageScrollView.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.

import SwiftUI

struct ProfileImageScroller: View {
    
    @Binding var vm: ProfileViewModel
    
    var body: some View {
        
        ScrollViewReader { proxy in
            ScrollView (.horizontal, showsIndicators: false) {
                HStack (spacing: 48) {
                    ForEach(vm.profile.images.indices, id: \.self) {index in
                        ZStack {
                            Image(vm.profile.images[index])
                                .resizable()
                                .scaledToFit( )
                                .frame(width: 60, height: 60)
                                .cornerRadius(16)
                                .shadow(color: vm.imageSelection == index ? Color.black.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 10)
                            if vm.imageSelection == index {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.accentColor, lineWidth: 1)
                                    .frame(width: 60, height: 60)
                            }
                        }
                        .id(index)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)){
                                vm.imageSelection = index
                            }
                        }
                    }
                }
                .padding()
            }
            .onChange(of: vm.imageSelection) {oldIndex, newIndex in
                if oldIndex < 3 && newIndex == 3 {
                    withAnimation {
                        proxy.scrollTo(newIndex, anchor: .leading)
                    }
                }
                if oldIndex >= 3 && newIndex == 2 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newIndex, anchor: .trailing)
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileImageScroller(vm: .constant(ProfileViewModel()))
}
