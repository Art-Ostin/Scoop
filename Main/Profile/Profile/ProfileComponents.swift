//
//  DetailsSection.swift
//  Scoop
//
//  Created by Art Ostin on 03/12/2025.
//


import SwiftUI

struct DetailsSection<Content: View>: View {
    let color: Color
    let content: Content
    
    init(color: Color = Color(red: 0.9, green: 0.9, blue: 0.9), @ViewBuilder content: () -> Content) {
        self.color = color
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 185, alignment: .topLeading)
        .stroke(20, lineWidth: 1, color: color)
        .padding(.horizontal, 16)
    }
}

struct InfoItem: View {
    let image: String
    let info: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            //Overlay method, ensures all images take up same space
            Rectangle()
                .fill(Color.clear)
                .frame(width: 20, height: 17)
                .overlay {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                }
            
            Text(info)
                .font(.body(17, .medium))
        }
    }
}

struct NarrowDivide: View {
    var body: some View {
        Rectangle()
            .foregroundColor(.clear)
            .frame(width: 0.7, height: 16)
            .background(Color(red: 0.9, green: 0.9, blue: 0.9))
    }
}

struct ProfileTitle: View {
    
    let p: UserProfile
    @Binding var selectedProfile: ProfileModel?
    
    var body: some View {
        HStack {
            Text(p.name)
            ForEach (p.nationality, id: \.self) {flag in Text(flag)}
            Spacer()
            profileDismissButton(selectedProfile: $selectedProfile, color: .black)
        }
        .font(.body(24, .bold))
        .padding(.horizontal)
    }
}

struct ProfileSecondTitle: View {
    
    let vm: ProfileViewModel
    @Binding var selectedProfile: ProfileModel?
    
    var body: some View {
        HStack {
            Text(vm.profileModel.profile.name)
            Spacer()
            profileDismissButton(selectedProfile: $selectedProfile, color: .white)
        }
        .font(.body(24, .bold))
        .foregroundStyle(.white)
        .padding(.top, 32)
        .padding(.horizontal, 16)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { start in
            Array(self[start..<Swift.min(start + size, count)])
        }
    }
}

struct ImageSectionBottom: PreferenceKey {
    let has_updated = false
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ImageSizeKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct TopSafeArea: PreferenceKey {
    static var defaultValue: CGFloat = 0
      static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
          value = max(value, nextValue())
      }
}
