//
//  DraftProfileView.swift
//  Scoop
//
//  Created by Art Ostin on 28/10/2025.
//

import SwiftUI

struct DraftProfileView: View {
    
    @State var vm: ProfileViewModel
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                
            }
            VStack {
                let screenWidth = proxy.size.width
                
                HStack(spacing: 4) {
                    let p = vm.profileModel.profile
                    Text(p.name)
                }
                ProfileImageView(vm: $vm, screenWidth: screenWidth)
                ProfileDetailsView(screenWidth: screenWidth, p: vm.profileModel.profile, event: vm.profileModel.event)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
