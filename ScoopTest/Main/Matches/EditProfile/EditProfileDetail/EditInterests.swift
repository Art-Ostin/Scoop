//
//  EditPassions.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI
import SwiftUIFlowLayout
import FirebaseFirestore


struct EditInterests: View {
    
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.flowMode) private var mode

    @State var selected: [String] = []
    
    
    var sections: [(title: String?, image: String?, data: [String])] {
        let i = Interests.instance
        return [
        ("Social","figure.socialdance",i.social),
        ("Interests", "book",i.passions),
        ("Activities","MyCustomShoe",i.passions),
        ("Sports","tennisball",i.sports),
        ("Music","MyCustomMic",i.music1),
        (nil,nil,i.music2),
        (nil,nil,i.music3)
        ]
    }

    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            VStack(spacing: 12) {
                
                SignUpTitle(text: "Interests", subtitle: "\(selected.count)/10")
                selectedInterestsView
                
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        
                        ForEach(sections.indices, id: \.self) { idx in
                            let section = sections[idx]
                            
                            InterestSection(options: section.data, title: section.title, image: section.image, selected: $selected)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 12)
            if case .onboarding(_, let advance) = mode {
                NextButton(isEnabled: selected.count > 3) {advance()}
            }
        }
        .flowNavigation()
        .task {
            selected = dependencies.userManager.user?.interests
            ?? dependencies.userManager.user?.character
            ?? []
        }
    }
}

extension EditInterests {
    
    private var selectedInterestsView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack {
                    ForEach(selected, id: \.self) { item in
                        optionCell2(text: item, selection: $selected) {text in
                            selected.removeAll { $0 == text }
                        }
                        .id(item)
                    }
                }
                .frame(height: 40)
            }
            .onChange(of: selected.count) {
                withAnimation {
                    proxy.scrollTo(selected.last, anchor: .trailing)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct InterestSection: View {
    
    @State var options: [String]
    
    let title: String?
    let image: String?
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies

    
    private func interestIsSelected (text: String) -> Bool {
        dependencies.userManager.user?.interests?.contains(text) == true
    }
    @Binding var selected: [String]
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            HStack(alignment: .center, spacing: 24) {
                if let image = image {
                    Image(image)
                        .resizable()
                        .frame(width: 22, height: 20)
                }
                if let title = title {
                    Text(title)
                        .font(.body(20))
                        .offset(y: 1)
                }
            }
            .padding(.horizontal, 5)
            .padding(.bottom, 16)
            
            FlowLayout(mode: .scrollable, items: options, itemSpacing: 6) { input in
                optionCell2(text: input, selection: $selected) { text in
                    selected.contains(text)
                        ? selected.removeAll(where: { $0 == text })
                        : (selected.count < 10 ? selected.append(text) : nil)

                    Task {
                        if interestIsSelected(text: text) {
                            try await dependencies.profileManager.update(values: [.interests : FieldValue.arrayRemove([text])])
                        } else {
                            try await dependencies.profileManager.update(values: [.interests : FieldValue.arrayUnion([text])])
                        }
                    }
                }
            }
            .offset(x: -5)
        }
        .padding(.bottom, (title == nil || title == "Music") ? 0 : 60)
        
    }
}

#Preview {
    EditInterests()
}

struct optionCell2: View {
    
    let text: String
    
    @Binding var selection: [String]
    
    let onTap: (String) -> Void
    
    var body: some View {
        Text(text)
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .font(.body(14))
            .foregroundStyle(selection.contains(text) ? Color.white : Color.black)
            .background (
                RoundedRectangle(cornerRadius: 12)
                    .fill(selection.contains(text) ? .accent : Color.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.90, green: 0.90, blue: 0.90), lineWidth: 1)
                    )
            )
            .onTapGesture {
                onTap(text)
            }
    }
}
