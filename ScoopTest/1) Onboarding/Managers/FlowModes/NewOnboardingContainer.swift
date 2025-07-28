//
//  NewOnboardingContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

struct NewOnboardingContainer: View {
    
    
    @State var vm = OnboardingViewModel()
    
    
    @Environment(\.appDependencies) private var dep
    @Environment(\.flowMode) private var mode
    
    @State var current: Int = 0
    
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                Group {
                    switch current {
                    case 0: OptionEditView(field: ProfileFields.editSex(dep: dep))
                    case 1: OptionEditView(field: ProfileFields.editAttractedTo(dep: dep))
                    case 2: OptionEditView(field: ProfileFields.editLookingFor(dep: dep))
                    case 3: OptionEditView(field: ProfileFields.editYear(dep: dep))
                    case 4: TextFieldEdit(field: ProfileFields.editHometown(dep: dep))
                    case 5: TextFieldEdit(field: ProfileFields.editDegree(dep: dep))
                    default: EmptyView()
                    }
                }
                .environment(\.flowMode, .onboarding(step: current) {
                    withAnimation { current += 1 }
                })
                .transition(vm.transition)
            }
        }
    }
}

#Preview {
    NewOnboardingContainer()
}

extension NewOnboardingContainer {
    
    private var sexField: OptionField {
        OptionField(
            title: "Sex",
            options: ["Man", "Women", "Beyond Binary"],
            keyPath: \.sex
        ) { value in
            try? await dep.profileManager.update(values: [.sex: value])
        }
    }

    private var attractedField: OptionField {
        OptionField(
            title: "Attracted To",
            options: ["Men", "Women", "Men & Women", "All Genders"],
            keyPath: \.attractedTo
        ) { value in
            try? await dep.profileManager.update(values: [.attractedTo: value])
        }
    }

    private var lookingField: OptionField {
        OptionField(
            title: "Looking For",
            options: ["Short-term", "Long-term", "Undecided"],
            keyPath: \.lookingFor
        ) { value in
            try? await dep.profileManager.update(values: [.lookingFor: value])
        }
    }

    private var yearField: OptionField {
        OptionField(
            title: "Year",
            options: ["U0", "U1", "U2", "U3", "U4"],
            keyPath: \.year
        ) { value in
            try? await dep.profileManager.update(values: [.year: value])
        }
    }

    private var degreeField: TextFieldField {
        TextFieldField(title: "Degree", keyPath: \.degree) { text in
            try? await dep.profileManager.update(values: [.degree: text])
        }
    }

    private var hometownField: TextFieldField {
        TextFieldField(title: "Hometown", keyPath: \.hometown) { text in
            try? await dep.profileManager.update(values: [.hometown: text])
        }
    }
}
