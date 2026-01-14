//
//  DetailsSection.swift
//  Scoop
//
//  Created by Art Ostin on 03/12/2025.
//


import SwiftUI

struct DetailsSection<Content: View>: View {
    let color: Color
    let title: String?
    let content: Content
    
    init(color: Color = Color(red: 0.9, green: 0.9, blue: 0.9), title: String? = nil, @ViewBuilder content: () -> Content) {
        self.color = color
        self.title = title
        self.content = content()
    }
    
    var body: some View {
            VStack(alignment: .leading, spacing: 18) {
                content
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 169)
            .stroke(20, lineWidth: 1, color: color)
            .padding(.horizontal, 16)
            .overlay(alignment: .topLeading) {
                if let title = self.title {
                    Text(title)
                        .customCaption()
                        .padding(.horizontal, 8)
                        .background(Color.background)
                        .offset(y: -6)
                        .padding(.horizontal, 36)
                }
            }
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

struct ProfileTitle: View {
    let p: UserProfile
    
    var body: some View {
        HStack {
            Text(p.name)
            ForEach (p.nationality, id: \.self) {flag in Text(flag)}
            Spacer()
            ProfileDismissButton(color: .black)
        }
        .offset(y: 4) // Hack to align to bottom of HStack
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
            ProfileDismissButton(color: .white)
        }
        .font(.body(24, .bold))
        .foregroundStyle(.white)
        .padding(.top, 32)
        .padding(.horizontal, 16)
    }
}

struct PromptView: View {
    
    let prompt: PromptResponse
    var count: Int {prompt.response.count}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(prompt.prompt)
                .font(.body(14, .italic))
            
            Text(prompt.response)
                .font(.title(24, .bold))
                .lineSpacing(8)
                .font(.title(28))
                .lineLimit( count > 90 ? 4 : 3)
                .minimumScaleFactor(0.6)
                .lineSpacing(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

/*
 @Binding var selectedProfile: ProfileModel?
 */
