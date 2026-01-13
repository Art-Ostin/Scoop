//
//  pDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//var isThreePrompts: Bool { p.prompt3.response.isEmpty == true }


import SwiftUI
import SwiftUIFlowLayout

struct ProfileDetailsView: View {
    
    @Bindable var vm: ProfileViewModel
    @Binding var isTopOfScroll: Bool
    @Binding var scrollSelection: Int?
    
    let p: UserProfile
    let event: UserEvent?
    let detailsOpen: Bool
    let detailsOffset: CGFloat
    
    @State private var totalHeight: CGFloat = 0
    
    @State var scrollBottom: CGFloat = 0
    var showProfileEvent: Bool { event != nil || p.idealMeetUp != nil}
    
    @State private var flowLayoutBottom: CGFloat = 0
    @State private var interestSectionBottom: CGFloat = 0
    @State private var interestScale: CGFloat = 1
    
    @Binding var showInvite: Bool
    
    var scrollThirdTab: Bool { showProfileEvent && !p.prompt3.response.isEmpty }
    
    var body: some View {
        
        ZStack(alignment: .top) {
            
            
            ScrollView(.vertical) {
                
                    
                    VStack(spacing: 24) {
                        
                        DetailsSection(color: detailsOpen ? .accent : Color.grayPlaceholder, title: "About") {UserKeyInfo(p: p)}

                         PromptView(prompt: p.prompt1)
                            .padding(24)
                            .padding(.vertical, 6)
                        
                        DetailsSection(color: .grayPlaceholder, title: "Interests & Character") {
                            UserInterests(p: p, interestScale: interestScale)
                                .padding(.vertical, interestScale == 0 ? 0 : -12)
                        }
                        .measure(key: InterestsBottomKey.self) {$0.frame(in: .named("InterestsSection")).maxY}
                        .onPreferenceChange(InterestsBottomKey.self) { interestSectionBottom = $0 }
                        .onPreferenceChange(FlowLayoutBottom.self) { flowLayoutBottom = $0 }
                        .onChange(of: flowLayoutBottom) {
                            updateInterestScale()
                        }

                         PromptView(prompt:  p.prompt2)
                            .padding(24)
                            .padding(.vertical, 6)


                        DetailsSection(title: "Extra Info") {UserExtraInfo(p: p)}
                        
                        if !p.prompt3.response.isEmpty {
                                PromptView(prompt: p.prompt3)
                                .padding(24)
                                .padding(.vertical, 6)
                        }
                    }
                    .offset(y: 36)
                    .padding(.bottom, 256)
            }
            .frame(height: 600)
            .coordinateSpace(.named("InterestsSection"))
            .onScrollGeometryChange(for: Bool.self) { geo in
                let y = geo.contentOffset.y + geo.contentInsets.top
                return y <= 0.5
            } action: { _, isAtTop in
                self.isTopOfScroll = isAtTop
            }
            .scrollDisabled(disableDetailsScroll)
            .overlay(alignment: .top) {
                VStack(spacing: 0) {
                    DeclineButton() {}
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                }
                .offset(y: 384)
            }
            .background(Color.background)
            .mask(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
            .stroke(30, lineWidth: 1, color: .grayPlaceholder)
            .measure(key: TopOfDetailsView.self) {$0.frame(in: .named("profile")).minY}
            .scrollIndicators(.hidden)
            
//            if !isTopOfScroll && detailsOpen {
//                ZStack(alignment: .top) {
//                    LinearGradient(
//                        colors: [.white,.white.opacity(0)],
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                    .frame(height: 40)
//                    .frame(maxWidth: .infinity)
//                    .padding(.horizontal, 16)
//                    .clipShape(
//                        UnevenRoundedRectangle(
//                            topLeadingRadius: 30,
//                            bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 30,
//                            style: .continuous
//                        )
//                    )
//                    .allowsHitTesting(false)
//                }
//            }
        }
        .overlay(alignment: .topTrailing) {
            if !isTopOfScroll && detailsOpen {
                Image(systemName: "chevron.down")
                    .font(.body(16, .bold))
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.background.opacity(0.93))
                    )
                    .padding()
                    .padding(.horizontal, 6)
            }
        }
//        .overlay(alignment: .topTrailing) {
//            InviteButton(vm: vm, showInvite: $showInvite)
//                .offset(y: 384)
//                .padding(.horizontal, 16)
//        }
    }
}



/*
 .font(.body(17, .bold))
 .frame(width: 40, height: 40)
 .background(
     RoundedRectangle(cornerSize: 4)
         .fill(Color.background)
 )
 .stroke(100, lineWidth: 1, color: .grayBackground)
 .contentShape(Circle())
 .shadow(color: .black.opacity(0.05), radius: 1.5, x: 0, y: 3)
 .padding(.horizontal, 16)
 .offset(y: -16)
 */


/*
 HStack(spacing: 12) {
     Text("Dismiss")
     Image(systemName: "chevron.down")
 }
 .font(.body(14, .medium))
 .frame(maxWidth: .infinity, alignment: .center)
 .padding(.top, 12)
 */

struct TopOfDetailsView: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension ProfileDetailsView {
    func updateInterestScale() {
        guard flowLayoutBottom > 0, interestSectionBottom > 0 else { return }
        guard flowLayoutBottom > interestSectionBottom else { return }
        let newScale = max(interestSectionBottom / flowLayoutBottom, 0.1)
        if newScale < interestScale {
            interestScale = newScale
        }
    }
    var disableDetailsScroll: Bool {
           !detailsOpen || detailsOpen && isTopOfScroll && detailsOffset > 0
    }
}




/*
 
 
 if showProfileEvent {
     DetailsSection(title: "\(p.name)'s preferred meet") {ProfileEvent(p: p, event: event)}
 } else {
     DetailsSection(){ PromptView(prompt: p.prompt1) }
 }
 
 DetailsSection(color: detailsOpen ? .accent : Color.grayPlaceholder, title: "About") {UserKeyInfo(p: p)}
 
 //Section 3:
 DetailsSection() {
     PromptView(prompt: showProfileEvent ? p.prompt1 : p.prompt2)
 }
 
 //Section 4:
 DetailsSection(color: .grayPlaceholder, title: "Interests & Character") {
     UserInterests(p: p, interestScale: interestScale)
         .padding(.vertical, interestScale == 0 ? 0 : -12)
 }
 .measure(key: InterestsBottomKey.self) {$0.frame(in: .named("InterestsSection")).maxY}
 .onPreferenceChange(InterestsBottomKey.self) { interestSectionBottom = $0 }
 .onPreferenceChange(FlowLayoutBottom.self) { flowLayoutBottom = $0 }
 .onChange(of: flowLayoutBottom) {
     updateInterestScale()
 }
 //Section 5:
 DetailsSection(title: "Extra Info") {
     UserExtraInfo(p: p)
 }
 
 if scrollThirdTab {
     DetailsSection() {
         PromptView(prompt: p.prompt2)
     }
     DetailsSection() {
         PromptView(prompt: p.prompt3)
     }
 } else if showProfileEvent {
     DetailsSection() {
         PromptView(prompt: p.prompt2)
     }
 } else if !p.prompt3.response.isEmpty {
     DetailsSection() {
         PromptView(prompt: p.prompt3)
     }
 }
 */




/*
 private var detailsScreen3: some View {
     ScrollView(.vertical) {
         VStack(spacing: 16) {
             DetailsSection(title: "Extra Info") {
                 UserExtraInfo(p: p)
             }
             if scrollThirdTab {
                 DetailsSection(color: .red) {
                     PromptView(prompt: p.prompt2)
                 }
                 DetailsSection(color: .blue) {
                     PromptView(prompt: p.prompt3)
                 }
             } else if showProfileEvent {
                 DetailsSection() {
                     PromptView(prompt: p.prompt2)
                 }
             } else if !p.prompt3.response.isEmpty {
                 DetailsSection(color: .blue) {
                     PromptView(prompt: p.prompt3)
                 }
             }
         }
         .offset(y: 12)
         .padding(.bottom, 300)
     }
     .scrollDisabled(!detailsOpen)
     .frame(height: scrollSelection == 2 ? 600 : 0)
     .onScrollGeometryChange(for: Bool.self) { geo in
         let y = geo.contentOffset.y + geo.contentInsets.top
         return y <= 0.5
     } action: { _, isAtTop in
         self.isTopOfScroll = isAtTop
     }
 }
 */

/*
 extension ProfileDetailsView {
     private var detailsScreen1: some View {
         VStack(spacing: 16) {
             DetailsSection(color: detailsOpen ? .accent : Color.grayPlaceholder, title: "About") {UserKeyInfo(p: p)}
                 if showProfileEvent {
                     DetailsSection(title: "\(p.name)'s preferred meet") {ProfileEvent(p: p, event: event)}
                 } else {
                     DetailsSection(){ PromptView(prompt: p.prompt1) }
             }
         }
         .offset(y: 16)
     }
     
     private var detailsScreen2: some View {
         VStack(spacing: 16) {
             DetailsSection(color: .grayPlaceholder, title: "Interests & Character") {
                 UserInterests(p: p, interestScale: interestScale)
                     .padding(.vertical, interestScale == 0 ? 0 : -12)
             }
             .measure(key: InterestsBottomKey.self) {$0.frame(in: .named("InterestsSection")).maxY}
             .onPreferenceChange(InterestsBottomKey.self) { interestSectionBottom = $0 }
             .onPreferenceChange(FlowLayoutBottom.self) { flowLayoutBottom = $0 }
             .onChange(of: flowLayoutBottom) {
                 updateInterestScale()
             }
             
             DetailsSection() {
                 PromptView(prompt: showProfileEvent ? p.prompt1 : p.prompt2)
             }
         }
         .offset(y: 16)
         .coordinateSpace(.named("InterestsSection"))
     }

     private var detailsScreen3: some View {
         ScrollView(.vertical) {
             VStack(spacing: 16) {
                 
                 
             }
             .offset(y: 16)
             .padding(.bottom, 300)
         }
         .scrollDisabled(disableDetailsScroll)
         .frame(height: scrollSelection == 2 ? 600 : 0)
         .onScrollGeometryChange(for: Bool.self) { geo in
             let y = geo.contentOffset.y + geo.contentInsets.top
             return y <= 0.5
         } action: { _, isAtTop in
             self.isTopOfScroll = isAtTop
         }
     }
 }
 */

