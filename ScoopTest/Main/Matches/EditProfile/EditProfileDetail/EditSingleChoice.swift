//
//  SingleChoiceEdit.swift
//  ScoopTest
//
//  Created by Art Ostin on 27/07/2025.
//

import SwiftUI


//Define the data Each OptionField Requires
struct OptionField {
    let title: String
    let options: [String]
    let keyPath: KeyPath<UserProfile, String?>
//    let update: (String) async -> Void
}


//Defines the generic layout for OptionSelectionView
struct OptionEditView: View  {
    
    @Binding var vm: EditProfileViewModel
    @State private var selection: String? = nil
    @Environment(\.flowMode) private var mode

    let field: OptionField
    
    
    

    var body: some View {
        let grid = [GridItem(.flexible()), GridItem(.flexible())]
        
        VStack {
            
            Text(field.title)
                .font(.title(32))
            
            LazyVGrid(columns: grid, spacing: 24) {
                ForEach(field.options, id: \.self) { option in
                    OptionPill(title: option, isSelected: $selection) {
                        select(option)
                    }
                }
            }
        }
        .flowNavigation()
        .onAppear {selection = vm.fetchUserField(\.attractedTo)}
    }
    
    private func select(_ value: String) {
        Task { vm.updateUser(values: [field.keyPath: value]) }
        switch mode {
        case .onboarding(_, let advance):
            advance()
        case .profile: break
        }
    }
}


// Defines the actual Views passing the information
struct ProfileFields {
    
    
    static func editSex(vm: EditProfileViewModel) -> OptionField {
        OptionField(
            title: "Sex",
            options: ["Man", "Women", "Beyond Binary"],
            keyPath: \.sex
        ) }
        
        

      static func editAttractedTo(dep: AppDependencies) -> OptionField {
          OptionField(
              title: "Attracted To",
              options: ["Men", "Women", "Men & Women", "All Genders"],
              keyPath: \.attractedTo
          ) { value in
              try? await dep.userManager.updateUser(values: [.attractedTo: value])
          }
      }

      static func editLookingFor(dep: AppDependencies) -> OptionField {
          OptionField(
              title: "Looking For",
              options: ["Short-term", "Long-term", "Undecided"],
              keyPath: \.lookingFor
          ) { value in
              try? await dep.userManager.updateUser(values: [.lookingFor: value])
          }
      }

      static func editYear(dep: AppDependencies) -> OptionField {
          OptionField(
              title: "Year",
              options: ["U0", "U1", "U2", "U3", "U4"],
              keyPath: \.year
          ) { value in
              try? await dep.userManager.updateUser(values: [.year: value])
          }
      }

      static func editDegree(dep: AppDependencies) -> TextFieldField {
          TextFieldField(title: "Degree", keyPath: \.degree) { text in
              try? await dep.userManager.updateUser(values: [.degree: text])
          }
      }
    
      static func editHometown(dep: AppDependencies) -> TextFieldField {
          TextFieldField(title: "Hometown", keyPath: \.hometown) { text in
              try? await dep.userManager.updateUser(values: [.hometown: text])
          }
      }
    
    
    static func editName(dep: AppDependencies) -> TextFieldField {
        TextFieldField(title: "Name", keyPath: \.name) { text in
            try? await dep.userManager.updateUser(values: [.name: text])
        }
    }

    static func editLanguages(dep: AppDependencies) -> TextFieldField {
        TextFieldField(title: "I Speak", keyPath: \.languages) { text in
            try? await dep.userManager.updateUser(values: [.languages: text])
        }
    }
    
}
