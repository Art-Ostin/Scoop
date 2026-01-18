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
            .nextButton(isEnabled: selected.count >= 6, padding: 120) {
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
            .onChange(of: selected) {
                print(selected)
            }
            .onDisappear {
                guard selected != vm.draft.interests else {
                    return
                }
                vm.set(.interests, \.interests, to: selected)
            }
            .padding(.top, 24)
            .background(Color.background)
    }
}

struct GenericInterests: View {
    
    @Binding var selected: [String]
    @State var currentScroll: Int? = 0
    @State var selectedScroll: Int? = 0
    @Namespace private var tabNamespace
    
    var selectedMax: Bool {selected.count >= 10}
    let onInterestTap: (String) -> ()
    
    var sections: [(title: String?, image: String?, data: [String])] {
        let i = Interests.instance
        return [
            ("Social","figure.socialdance",i.social),
            ("Interests", "book",i.passions),
            ("Sports","tennisball",i.sports),
            ("Music","MyCustomMic",i.music1),
            (nil,nil,i.music2),
            (nil,nil,i.music3)
        ]
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            scrollTitle(selectedCount: selected.count, totalCount: 10, title: "Passions")
            selectedInterestsView.zIndex(2)
            scrollFader().zIndex(1)
            interestsSections
            scrollToSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.background)
    }
}


extension GenericInterests {
    private var selectedInterestsView: some View {
        ZStack {
            if selected.isEmpty {
                Text("Choose at least 6")
                    .font(.body(16, .italic))
                    .foregroundStyle(Color.grayText)
                    .offset(y: 12)
            }
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(alignment: .bottom) {
                        ClearRectangle(size: 10)
                        ForEach(selected, id: \.self) { selection in
                            OptionCell(text: selection, selection: $selected, fillColour: false) { text in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selected.removeAll { $0 == text }
                                }
                            }
                            .offset(y: 5)
                        }
                        ClearRectangle(size: 30)
                            .id("End Scroll")
                    }
                    .frame(height: 48)
                }
                .onChange(of: selected.count) { oldValue, newValue in
                    if newValue > oldValue {
                        Task {
                            try? await Task.sleep(nanoseconds: 50_000_000)
                            withAnimation(.easeInOut(duration: 0.4)) { proxy.scrollTo("End Scroll", anchor: .trailing) }
                        }
                    }
                }
                .scrollIndicators(.never)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
            }
        }
    }

    @ViewBuilder
    private var interestsSections: some View {
        let topPadding: CGFloat = 60
        
        ScrollView(.vertical) {
            
            VStack(spacing: 0) {
                ClearRectangle(size: 32)
                
                ForEach(sections.indices, id: \.self) { idx in
                    let section = sections[idx]
                    InterestSection(options: section.data, title: section.title, image: section.image, selected: $selected) { text in
                        onInterestTap(text)
                    }
                }
            }
            .scrollTargetLayout()
            .padding(.bottom, 118)
        }
        .scrollContentBackground(.hidden)
        .scrollPosition(id: $currentScroll, anchor: .leading)
        .padding(.top, topPadding)
        .scrollIndicators(.never)
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.4), value: currentScroll)
    }
    
    private var scrollToSection: some View {
        CustomScrollTab(height: 20) {
            HStack {
                let scroll = min(currentScroll ?? 0, 3)
                ForEach(0...3, id: \.self) { idx in
                    let section = sections[idx]
                    let isSelected = scroll == idx
                    Text(section.title ?? "")
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentScroll = idx
                            }
                        }
                        .foregroundStyle(isSelected ? .accent : .black)
                        .overlay {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 16)
                                    .frame(width: idx == 1 ? 65 : 50, height: 3)
                                    .foregroundStyle(Color.accent)
                                    .offset(y: 12)
                                    .matchedGeometryEffect(id: "tabUnderline", in: tabNamespace)
                            }
                        }
                    if idx != 3 {
                        Spacer()
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentScroll)
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
    
    
    @State private var flashMaxText: Set<String> = []

    
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
                OptionCell(text: input,
                           selection: $selected,
                           overlayText: flashMaxText.contains(input) ? "max 10" : nil) { text in
                    let tapped = text
                    if selected.contains(tapped) {
                        onInterestTap(tapped)
                    } else if selected.count >= 10 {
                        shakeTicks[tapped, default: 0] &+= 1
                        flashMaxText.insert(tapped)
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                                flashMaxText.remove(tapped)
                        }
                    } else {
                        onInterestTap(tapped)
                    }
                }
                .modifier(Shake(animatableData: CGFloat(shakeTicks[input, default: 0])))
                .animation(.easeInOut(duration: 0.6), value: shakeTicks[input, default: 0])
                .animation(.easeInOut(duration: 0.4), value: flashMaxText)
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
    let fillColour: Bool
    let overlayText: String?
    init(text: String, selection: Binding<[String]>, fillColour: Bool = true, overlayText: String? = nil, onTap: @escaping (String) -> Void) {
        self.text = text
        self._selection = selection
        self.fillColour = fillColour
        self.overlayText = overlayText
        self.onTap = onTap
    }
    
    var body: some View {
        
        let isSelected = selection.contains(text)

        Text(text)
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .font(.body(14))
            .foregroundStyle(isSelected && fillColour ? Color.white : Color.black)
            .background (
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected && fillColour ? Color.accent : Color.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected && !fillColour ? .accent : Color(red: 0.90, green: 0.90, blue: 0.90), lineWidth: 1)
                    )
            )
            .overlay {
                if let overlayText {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.background.opacity(1))
                        Text(overlayText)
                            .font(.body(14))
                            .foregroundStyle(Color.accent)
                    }
                    .allowsHitTesting(false)
                }
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onTap(text)
                }
            }
            .overlay(alignment: .topTrailing) {
                CircleIcon("xmark")
                    .opacity(selection.contains(text) ? 1 : 0)
                    .offset(x: 6,  y: -6)
            }
    }
}

