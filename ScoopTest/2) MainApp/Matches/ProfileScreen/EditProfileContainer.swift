//
//  EditProfileView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/07/2025.
//

import SwiftUI


@Observable class EditProfileViewModel {
    var nameTextField: String = "Arthur"
    var hometownTextField: String = "London"
    var degreeTextField: String = "Politics"
}

struct EditProfileView: View {
    
    @State var selectedIndex: Bool = true

    @State var vm = EditProfileViewModel()
    
    @FocusState var isFocused: Bool
    
    @State var coreInfo: [ProfileInfoPreview<AnyView>] = []
    @State var aboutMe: [ProfileInfoPreview<AnyView>] = []
    @State var optional: [ProfileInfoPreview<AnyView>] = []

    
    var body: some View {
        
        let sections: [(title: String, data: [ProfileInfoPreview<AnyView>])] = [
            ("Core Info", coreInfo), ("About Me", aboutMe), ("Optional", optional)]
        
        NavigationStack {
            ZStack {
                ScrollView {
                    
                    EditImageView()
                        .padding(.horizontal, 32)

                    
                    Prompts()
                    
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
                                .padding(.bottom, info.id == section.data.last?.id ? 8: 0)
                                .padding(.top, info.id == section.data.first?.id ? 8: 0)
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    SelectYears()
                }
                ViewProfileButton()
            }
            .navigationTitle("Profile")
            .background(Color(red: 0.97, green: 0.98, blue: 0.98))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { XButton {} }
                ToolbarItem(placement: .topBarTrailing) {
                    Text("Save")
                        .font(.body(14, .bold))
                }
            }
            .onAppear {
                coreInfo = [
                    ProfileInfoPreview("Name", ["Arthur"])
                    {AnyView(EditTextFieldType(title: "Name", textFieldText: $vm.nameTextField, isFocused: $isFocused))},
                    ProfileInfoPreview("Sex", ["Male"]) {AnyView(SexSelection())},
                    ProfileInfoPreview("Attracted to", ["Women"]) {AnyView(AttractedTo())},
                    ProfileInfoPreview("Year", ["U3"]) {AnyView(YearSelection())},
                    ProfileInfoPreview("Height", ["193cm"]) {AnyView(HeightSelection())}
                ]
                
                aboutMe = [
                    ProfileInfoPreview("Nationality", ["Britain", "France", "Sweden"]){AnyView(NationalityView())},
                    ProfileInfoPreview("Hometown", ["London"]){AnyView(EditTextFieldType(title: "Hometown", textFieldText: $vm.hometownTextField, isFocused: $isFocused))},
                    ProfileInfoPreview("Degree", ["Politics, Philosophy, Economics"]){AnyView(EditTextFieldType(title: "Hometown", textFieldText: $vm.degreeTextField, isFocused: $isFocused))},
                    ProfileInfoPreview("Passions", ["Free Climbing", "Rugby", "Skiing", "Chess"]){AnyView(InterestsSelection())},
                    ProfileInfoPreview("Activities",["Running", "Football", "Cold Water Swimming", "Free Climbing"]) {AnyView(HobbiesSelection())},
                    ProfileInfoPreview("Music",["Techno", "Electronica"]) {AnyView(MusicSelection())},
                    ProfileInfoPreview("Socials",["Raves", "Pub", "House Party"]) {AnyView(SocialPassionsSelection())},
                    ProfileInfoPreview("Lifestyle",["Drugs", "Marajuana", "smoking", "Drinking"]) {AnyView(SettingsView())}
                ]
                
                optional = [
                    ProfileInfoPreview("Song",["If U Ever - Overmono"]) {AnyView(EmbodyYou())},
                    ProfileInfoPreview("Politics",["liberal"]) {AnyView(SettingsView())},
                    ProfileInfoPreview("Religion",["Atheist"]) {AnyView(SettingsView())},
                    ProfileInfoPreview("Ethnicity",["White caucasion"]) {AnyView(SettingsView())},
                    ProfileInfoPreview("Lanuages", ["English, French"]) {AnyView(SettingsView())}
                ]
            }
            }
        }
    }

#Preview {
    EditProfileView()
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
