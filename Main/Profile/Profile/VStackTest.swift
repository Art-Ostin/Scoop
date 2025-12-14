//
//  VStack Test.swift
//  Scoop
//
//  Created by Art Ostin on 13/12/2025.
//

import SwiftUI

struct VStackTest: View {
    
    @Binding var selectedProfile: ProfileModel?
    
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 20).frame(height: 300).foregroundStyle(.red)
                RoundedRectangle(cornerRadius: 20).frame(height: 300).foregroundStyle(.red)
                RoundedRectangle(cornerRadius: 20).frame(height: 500).foregroundStyle(.green)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea(edges: .bottom)
            .onTapGesture { selectedProfile = nil}
        }
    }
}

