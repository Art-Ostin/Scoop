//
//  Test.swift
//  ScoopTest
//
//  Created by Art Ostin on 22/07/2025.
//

import SwiftUI

struct Test: View {
    var body: some View {
        
        Text(EditProfileViewModel.instance.user?.name ?? "No Name")
        
        
        
    }
}

#Preview {
    Test()
}
