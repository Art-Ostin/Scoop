//
//  InfoView.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.


import SwiftUI

struct InfoView: View {
    
    @State var coreInfo: [ProfileInfoPreview<AnyView>] = []
    @State var aboutMe: [ProfileInfoPreview<AnyView>] = []
    
    
    @State var user = EditProfileViewModel.instance.user
    
    @FocusState var isFocused: Bool

    var body: some View {
        
        let sections: [(title: String, data: [ProfileInfoPreview<AnyView>])] = [
            ("Core", coreInfo), ("About", aboutMe)]
        
        ScrollView {
            ForEach(sections, id: \.title) {section in
                CustomList(title: section.title) {
                    ForEach(section.data) { info in
                        VStack(spacing: 0) {
                                ListItem(title: info.title, response: info.response, destination: info.destination)
                                if info.id != section.data.last?.id {
                                    SoftDivider()
                                        .padding(.leading, 24)
                                        .foregroundStyle(.red)
                                }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, 32)
        
        .onAppear {
            coreInfo = [
                ProfileInfoPreview("Name", ["Arthur"])
                {AnyView(EditTextFieldLayout(isOnboarding: false, title: "Name"))},
                ProfileInfoPreview("Sex", ["Male"]) {AnyView(EditSex(title: "Sex"))},
                ProfileInfoPreview("Attracted to", ["Women"]) {AnyView(EditAttractedTo(title: "Attracted to"))},
                ProfileInfoPreview("Year", ["U3"]) {AnyView(EditYear(title: "Year"))},
                ProfileInfoPreview("Height", ["193cm"]) {AnyView(EditHeight(title: "Height"))},
                ProfileInfoPreview("Nationality", ["🇬🇧  🇫🇷  🇸🇪"]){AnyView(EditNationality(isOnboarding: false))}
            ]
            
            
            
            
            aboutMe = [
                ProfileInfoPreview("Looking for", ["Casual"]){AnyView( EditLookingFor())},
                ProfileInfoPreview("Degree", ["Economics"]){AnyView(EditTextFieldLayout(isOnboarding: false, title: "Degree"))},
                ProfileInfoPreview("Hometown", ["London"]){AnyView(EditTextFieldLayout(isOnboarding: false, title: "Hometown"))},
                ProfileInfoPreview("Lifestyle",["Drinking", "Smoking", "Marajuana", "Drugs"]) {AnyView(EditLifestyle())},
                ProfileInfoPreview("My Life as", ["Overmono"]) {AnyView(EditMyLifeAs())},
                ProfileInfoPreview("Languages", ["English, French"]) {AnyView(EditTextFieldLayout(isOnboarding: false, title: "I Speak"))}
            ]
        }
    }
}

#Preview {
    InfoView()
}

struct ProfileInfoPreview<Content: View>: Identifiable {
    let id = UUID()
    let title: String
    let response: [String]
    let destination: () -> Content
    
    init(_ title: String, _ response: [String], @ViewBuilder _ destination: @escaping () -> Content) {
        self.title = title
        self.response = response
        self.destination = destination
    }
}
