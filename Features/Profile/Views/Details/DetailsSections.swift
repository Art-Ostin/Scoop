//
//  DetailsInfo.swift
//  Scoop
//
//  Created by Art Ostin on 02/11/2025.


import SwiftUI
import SwiftUIFlowLayout


struct UserKeyInfo: View {
    let p : UserProfile
    var hometownCount: Int { p.hometown.count}
    
    var body : some View {
        if hometownCount <= 14 {
            keyInfoOneLine
        } else {
            keyInfoScrollView
        }
        Divider().background(Color.border)
        InfoItem(image: "ScholarStyle", info: p.degree)
        Divider().background(Color.border)
        InfoItem(image: "magnifyingglass", info: p.lookingFor)
    }
}

extension UserKeyInfo {

    private var keyInfoOneLine: some View {
        HStack(alignment: .center) {
                InfoItem(image: "Year", info: p.year)
                Spacer()
                InfoItem(image: "Height", info: ("193cm"))
                Spacer()
                InfoItem(image: "House", info: p.hometown)
            }
    }
    
    private var keyInfoScrollView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.lg) {
                InfoItem(image: "Year", info: p.year)
                InfoItem(image: "Height", info: ("193cm"))
                InfoItem(image: "House", info: p.hometown)
            }
        }
        .padding(.vertical, Spacing.sm) //Trick to expand the tap area of the view so scrolls easier
        .contentShape(Rectangle())
        .padding(.vertical, -12)
    }
}


struct UserInterests: View {
    let p: UserProfile

    var body: some View {
        FlowLayout(mode: .vstack, items: p.interests, itemSpacing: 6) { text in
            Text(text)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .font(.body(16))
                .stroke(CornerRadius.sm)
        }
        .padding(.horizontal, -12)
    }
}
