//
//  EditPassions.swift
//  Scoop
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI
import SwiftUIFlowLayout
import FirebaseFirestore

struct OnboardingInterests: View {
    //Injected
    let vm: OnboardingViewModel

    //Local view state
    @State private var selected: [String] = []

    var body: some View {
        GenericInterests(selected: $selected)
            .nextButton(isValid: selected.count >= 6, padding: 120) {
                vm.saveAndNextStep(kp: \.interests, to: selected)
            }
            .onAppear {
                if let draft = vm.draftProfile {
                    if !draft.interests.isEmpty {
                        selected = draft.interests
                    }
                }
            }
    }
}

struct EditInterests: View {
    //Injected
    @Environment(\.dismiss) private var dismiss
    let vm: EditProfileViewModel

    //Local view state
    @State private var selected: [String]
    @State private var showEmptyAlert = false

    init(vm: EditProfileViewModel) {
        self.vm = vm
        _selected = .init(wrappedValue: vm.draft.interests)
    }
    
    var body: some View {
        GenericInterests(selected: $selected)
            .closeAndCheckNavButton(check: selected.count < 6, triggerAlert: $showEmptyAlert)
            .onDisappear {
                guard selected != vm.draft.interests else { return}
                vm.set(.interests, \.interests, to: selected)
            }
            .customAlert(isPresented: $showEmptyAlert, message: "Please select at least 6 interests", showTwoButtons: false, onOK: {showEmptyAlert.toggle()})
    }
}

struct GenericInterests: View {
    
    //Injected
    @Binding var selected: [String]

    //Local view state
    @State private var currentScroll: Int? = 0
    @State private var selectedScroll: Int? = 0
    @State private var selectedScrollPos = ScrollPosition()
    @Namespace private var tabNamespace

    private let maxCount = 10

    var sections: [(title: String?, image: String?, data: [String])] {
        let i = Interests.instance
        return [
            ("Social","figure.socialdance",i.social),
            ("Interests", "BookIcon",i.passions),
            ("Sports","tennisball",i.sports),
            ("Music","MyCustomMic",i.music1),
            (nil,nil,i.music2),
            (nil,nil,i.music3)
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollTitle(selectedCount: selected.count, totalCount: maxCount, title: "Passions")
            selectedInterestsView
            interestsSections
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appCanvas.ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            scrollToSection
        }
    }
}

extension GenericInterests {
    private var selectedInterestsView: some View {
            ScrollView(.horizontal) {
                HStack(alignment: .top) {
                    ForEach(selected, id: \.self) { selection in
                        OptionCell(text: selection, selection: $selected, style: .outlined)
                            .offset(y: 5) //Geometry: drops the chips clear of the title baseline
                    }
                }
                .frame(height: 45)
            }
            .contentMargins(.all, EdgeInsets(top: 0, leading: Spacing.md, bottom: 0, trailing: Spacing.xl), for: .scrollContent)
            .scrollPosition($selectedScrollPos)
            .onChange(of: selected.count) { oldValue, newValue in
                if newValue > oldValue {
                    Task {
                        try? await Task.sleep(nanoseconds: 50_000_000)
                        withAnimation(.move) { selectedScrollPos.scrollTo(edge: .trailing) }
                    }
                }
            }
            .scrollIndicators(.never)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }

    @ViewBuilder
    private var interestsSections: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                ForEach(sections.indices, id: \.self) { idx in
                    let section = sections[idx]
                    InterestSection(options: section.data, title: section.title, image: section.image, selected: $selected, maxCount: maxCount)
                }
            }
            .contentMargins(.top, Spacing.xl)
            .scrollTargetLayout()
            .padding(.bottom, Spacing.clearance)
        }
        .scrollContentBackground(.hidden)
        .scrollPosition(id: $currentScroll, anchor: .leading)
        .scrollIndicators(.never)
        .padding(.horizontal)
        .animation(.move, value: currentScroll)
        .customScrollFade(height: 50, showFade: true)
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
                            withAnimation(.toggle) {
                                currentScroll = idx
                            }
                        }
                        .foregroundStyle(isSelected ? .accent : .black)
                        .overlay {
                            if isSelected {
                                RoundedRectangle(cornerRadius: CornerRadius.md)
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
            .animation(.toggle, value: currentScroll)
        }
        .padding(.bottom, Spacing.sm)
        .padding(.horizontal)
    }
}


struct InterestSection: View {
    
    let options: [String]
    let title: String?
    let image: String?

    @Binding var selected: [String]

    let maxCount: Int

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center, spacing: Spacing.lg) {
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
            .padding(.horizontal, Spacing.xxs)
            .padding(.bottom, Spacing.md)

            FlowLayout(mode: .scrollable, items: options, itemSpacing: Spacing.xs) { input in
                OptionCell(text: input, maxCount: maxCount, selection: $selected)
            }
            .offset(x: -Spacing.xxs) //Keeps the chips aligned with the section header
        }
        .padding(.bottom, (title == nil || title == "Music") ? 0 : 60)
    }
}
