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
            .onDisappear {vm.draft.interests = selected}
    }
}

struct GenericInterests: View {
    
    
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
    
    
    private var progress: CGFloat {
        guard contentHeight > 0, scrollViewHeight > 0 else { return 0 }
        let maxOffset = max(contentHeight - scrollViewHeight, 0)
        if maxOffset == 0 {
            // Content fits without scrolling – treat as 100%
            return 1
        }
        let p = scrollOffset / maxOffset
        return min(max(p, 0), 1)   // clamp to 0...1
    }
    
    
    @Binding var selected: [String]
    var selectedMax: Bool {selected.count >= 10}
    let onInterestTap: (String) -> ()
    
    var sections: [(title: String?, image: String?, data: [String])] {
        let i = Interests.instance
        return [
            ("What I do for Social","figure.socialdance",i.social),
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
        .onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }
        .onPreferenceChange(ContentHeightKey.self) { contentHeight = $0 }
        .onPreferenceChange(ScrollViewHeightKey.self) { scrollViewHeight = $0 }
    }
}


extension GenericInterests {
    private var selectedInterestsView: some View {
        ZStack {
            if selected.isEmpty {
                Text("Choose a minimum 6")
                    .font(.body(16, .italic))
                    .foregroundStyle(Color.grayText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)
            }
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    
                    HStack(alignment: .bottom) {
                        Rectangle()
                            .fill(.clear)
                            .frame(width: 10)
                        
                        ForEach(selected, id: \.self) { item in
                            OptionCell(text: item, selection: $selected) {text in
                                selected.removeAll { $0 == text }
                            }
                            .id(item)
                        }
                        
                        Rectangle()
                            .fill(.clear)
                            .frame(width: 10)
                    }
                    .frame(height: 48)
                }
                .scrollIndicators(.never)
                .onChange(of: selected.count) {oldValue, newValue in
                    if oldValue < newValue {
                        withAnimation {proxy.scrollTo(selected.last, anchor: .trailing)}
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.top, 12)
    }
    
    @ViewBuilder
    private var interestsSections: some View {
        let topPadding: CGFloat = 60
        
        ScrollView(.vertical) {
            
            GeometryReader { proxy in
                Color.clear
                    .preference(key: ScrollOffsetKey.self,
                                value: -proxy.frame(in: .named("scroll")).minY)
            }
            .frame(height: 0)
            
            
            LazyVStack(spacing: 0) {
                Rectangle()
                    .fill(.clear)
                    .frame(height: 32)
                
                ForEach(sections.indices, id: \.self) { idx in
                    let section = sections[idx]
                    InterestSection(options: section.data, title: section.title, image: section.image, selected: $selected) { text in
                        onInterestTap(text)
                    }
                }
            }
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: ContentHeightKey.self,
                                    value: proxy.size.height)
                }
            )
            .padding(.bottom, 118)
        }
        .coordinateSpace(name: "scroll")
        .padding(.top, topPadding)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: ScrollViewHeightKey.self,
                                value: proxy.size.height)
            }
        )
        .scrollIndicators(.never)
        .padding(.horizontal)
    }
    
    private var scrollToSection: some View {
        
        HStack {
            Text("Social")
            Spacer()
            Text("Interests")
            Spacer()
            Text("Sports")
            Spacer()
            Text("Music")
        }
        .overlay(alignment: .bottomLeading) {
            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 15)
                    .frame(width: (proxy.size.width * progress), height: 3)
                    .foregroundStyle(Color(.accent))
            }
            .frame(height: 3)
            .offset(y: 8)
        }
        .onTapGesture {}
        .font(.body(16, .bold))
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .glassRectangle()
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 36)
        .padding(.horizontal)
        
        
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


private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

private struct ScrollViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}
