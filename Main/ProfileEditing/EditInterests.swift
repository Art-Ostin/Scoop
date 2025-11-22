//
//  EditPassions.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI
import SwiftUIFlowLayout
import FirebaseFirestore

struct OnboardingInterests: View {
    let vm: OnboardingViewModel
    
    @State var selected: [String] = []
    
    var body: some View {
        GenericInterests(selected: $selected) {selected.toggle($0, limit: 10)}
            .nextButton(isEnabled: selected.count >= 6){
                vm.saveAndNextStep(kp: \.interests, to: selected)
            }
    }
}

struct EditInterests: View {
    let vm: EditProfileViewModel
    @State var selected: [String]
    
    init(vm: EditProfileViewModel) {
        self.vm = vm
        _selected = .init(wrappedValue: vm.draft.interests)
    }
    
    var body: some View {
        GenericInterests(selected: $selected) {selected.toggle($0, limit: 10)}
        .onDisappear {vm.draft.interests = selected}
    }
}


struct GenericInterests: View {
    
    @Binding var selected: [String]
    var selectedMax: Bool {selected.count >= 10}
    let onInterestTap: (String) -> ()
    
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
            VStack(spacing: 4) {
                SignUpTitle(text: "Interests", subtitle: "\(selected.count)/10")
                selectedInterestsView
                interestsSections
            }
            .padding(.top, 12)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background.ignoresSafeArea())
    }
}

extension GenericInterests {
    
    private var interestsSections: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(sections.indices, id: \.self) { idx in
                    let section = sections[idx]
                    InterestSection(options: section.data, title: section.title, image: section.image, selected: $selected) { text in
                        onInterestTap(text)
                    }
                }
            }
        }
    }
    
    private var selectedInterestsView: some View {
        
        ZStack {
            
            if selected.isEmpty {
                Text("Choose a minimum 6")
                    .font(.body(16, .italic))
                    .foregroundStyle(Color.grayText)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(alignment: .bottom) {
                        ForEach(selected, id: \.self) { item in
                            OptionCell(text: item, selection: $selected) {text in
                                selected.removeAll { $0 == text }
                            }
                            .id(item)
                        }
                    }
                    .frame(height: 48)
                }
                .scrollIndicators(.never)
                .padding(.horizontal, -16)
                .onChange(of: selected.count) {oldValue, newValue in
                    if oldValue < newValue {
                        withAnimation {proxy.scrollTo(selected.last, anchor: .trailing)}
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

struct InterestSection: View {
    
    let options: [String]
    let title: String?
    let image: String?
    @State private var shakeTicks: [String: Int] = [:]

    @Binding var selected: [String]
    
    let onInterestTap: (String) -> ()

    var selectedMax: Bool {selected.count >= 10}
    
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
            
            FlowLayout(mode: .scrollable, items: options, itemSpacing: 6) {input in
                OptionCell(text: input, selection: $selected) {
                    if selected.contains($0) {
                        onInterestTap($0)
                    } else if selected.count >= 10 {
                        shakeTicks[$0, default: 0] &+= 1
                    } else {
                        onInterestTap($0)
                    }
                }
                .modifier(Shake(animatableData: CGFloat(shakeTicks[input, default: 0])))
                .animation(.easeInOut(duration: 0.3), value: shakeTicks[input, default: 0])
            }
            .offset(x: -5)
        }
        .padding(.bottom, (title == nil || title == "Music") ? 0 : 60)
    }
}

struct OptionCell: View {
    
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
            .overlay(alignment: .topTrailing) {
                CircleIcon("xmark")
                    .opacity(selection.contains(text) ? 1 : 0)
                    .offset(x: 6,  y: -6)
            }
    }
}

struct OptionCellProfile: View {
    
    let text: String
    
        var body: some View {
        Text(text)
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .font(.body(14))
            .foregroundStyle(Color.black)
            .background (
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.90, green: 0.90, blue: 0.90), lineWidth: 1)
                    )
            )
        }
}

struct OptionCellProfile2: View {
    let infoItem: InfoItemStruct
    var body: some View {
        HStack(spacing: 16) {
            Image(infoItem.image)
                .resizable()
                .scaledToFit()
                .frame(height: 17)
            
            Text(infoItem.info)
                .font(.body(14))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .foregroundStyle(Color.black)
        .background (
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.90, green: 0.90, blue: 0.90), lineWidth: 1)
                )
        )
    }
}


struct Shake: GeometryEffect {
    var travel: CGFloat = 8
    var shakes: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let x = travel * sin(animatableData * .pi * shakes)
        return ProjectionTransform(CGAffineTransform(translationX: x, y: 0))
    }
}
