//
//  DraftProfileView.swift
//  Scoop
//
//  Created by Art Ostin on 28/10/2025.
//

import SwiftUI

struct DraftProfileView: View {
    
    @State var vm: ProfileViewModel
    @State var showInvite: Bool = false
    
    @State var scrollSelection: Int?
    
    var body: some View {
        VStack {
            
            HStack(spacing: 4) {
                let p = vm.profileModel.profile
                Text(p.name)
            }
//            ProfileImageView(vm: vm, showInvite: $showInvite, detailsOffset: 32, firstImage: vm.profileModel.image!)
        }
        .frame(maxWidth: .infinity)
    }
}
