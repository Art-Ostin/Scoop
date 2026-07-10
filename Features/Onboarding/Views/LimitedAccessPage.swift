//
//  OnboardingHomePage.swift
//  Scoop
//
//  Created by Art Ostin on 03/12/2025.
//

import SwiftUI

struct LimitedAccessPage: View {
    
    let page: OnboardingPage
    
    @Binding var showOnboarding: Bool
    @Binding var showLogout: Bool
    let onboardingStep: Int
    
    var body: some View {
        VStack(spacing: 60) {
            Text(page.title)
                .font(.title())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(page.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240)
            
            Text(page.description)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)
                .font(.body(18, .medium))
            
            if !showOnboarding { //fixes bug where it sometimes appears 'underneath' prompt view.
                ActionButton(text: onboardingStep == 0 ? "Create Profile" : "Complete \(onboardingStep)/12", hPadding: 24) {
                    showOnboarding = true
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .overlay(alignment: .topTrailing) {
                signOutButton
                    .padding(.top, 24)
        }
        .background(Color.appCanvas)
    }
}

extension LimitedAccessPage {
    private var signOutButton: some View {
        Button {
            showLogout = true
        } label: {
            Text("Sign out")
                .font(.body(14, .bold))
                .padding(8)
                .foregroundStyle(Color.textPrimary)
                .background (
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.white )
                        .chipShadow()
                )
                .overlay (
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(.black, lineWidth: 1)
                )
                .padding(.horizontal, 16)
        }
    }
}


enum OnboardingPage: CaseIterable {
    
    case meet, meeting, message
    
    var title: String { data.title }
    var imageName: String {data.imageName}
    var description: String {data.description}
    
    private var data: (title: String, imageName: String, description: String) {
        switch self {
        case .meet: ("Meet", "Plants", "View weekly profiles here & send a Time and Place to Meet.")
        case .meeting: ("Meeting", "EventCups", "Details for upcoming meet ups appear here.")
        case .message: ("Message", "DancingCats", "View & message your previous matches here")
        }
    }
}
