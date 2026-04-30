//
//  ProfileDismissal.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI

extension ProfileView {

    var profileBackground: some View {
        UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
            .fill(Color.background)
            .ignoresSafeArea()
    }
}
