//
//  IdealMeetupView.swift
//  Scoop
//
//  Created by Art Ostin on 20/09/2026.
//

import SwiftUI
import SwiftUIFlowLayout



struct IdealMeetupView: View {
    
    let vm: EditProfileViewModel

    var activities: [String] { vm.draft.meetupPreferences.preferredActivities}
    var preferredDays: [String] { vm.draft.meetupPreferences.preferredDays}
    var dreamMeetup: String { vm.draft.meetupPreferences.dreamDate}
    
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    let vPadding: CGFloat = 20
    let hPadding: CGFloat = 20
        
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                whatSection
                whenSection
                dreamTextSection
            }
            .overlay(alignment: .topTrailing) {
                Image(noPreferencesYet() ? "EditButton" : "EditGray")
            }
            .listRowInsets(EdgeInsets(top: vPadding, leading: 0, bottom: vPadding, trailing: 0))
        }  header: {
            Text("Meetup Preferences")
                .padding(.leading, -Spacing.sm) //Geometry: negates the header's row inset so it lines up with the large title
        }
        .editorLink(.meetupPreferences)
    }
}


extension IdealMeetupView {
    
    private var whatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title: "What:")
                .padding(.horizontal, hPadding)
            ScrollView(.horizontal) {
                HStack(spacing: 24) {
                    ForEach(activities, id: \.self) { activity in
                        whatBubble(typeText: activity)
                    }
                }
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .customHScrollFade(color: .white)
        }
    }
    
    private var whenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title: "When:")
                .padding(.horizontal, hPadding)

            HStack {
                ForEach(days, id: \.self) { day in
                    dayBubble(day: day, isActive: preferredDays.contains(day))
                    if day != days.last { Spacer() }
                }
            }
            .padding(.horizontal, hPadding)
        }
    }
    
    private var dreamTextSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(title: "The Dream Date:")
            dreamDateText(dreamDate: dreamMeetup)
        }
        .padding(.horizontal, hPadding)
    }
}

//Components
extension IdealMeetupView {
    
    private func addPreferences(text: String) -> some View {
        Text(text)
            .foregroundStyle(Color.accent)
            .font(.body(14, .medium))
    }
    
    private func sectionTitle(title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .medium).italic())
            .foregroundStyle(Color.black.opacity(0.5))
    }
    
    
    private func whatBubble(typeText: String) -> some View {
        Text(typeText)
            .font(.body(14, .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .capsuleStroke(lineWidth: 1, color: Color.textPlaceholder)
    }
    
    private func dayBubble(day: String, isActive: Bool) -> some View {
        Text(day)
            .font(.body(13, .medium))
            .foregroundStyle(Color.textPrimary)
            .frame(width: 34, height: 34)
            .capsuleStroke(lineWidth: 1, color: Color.textPlaceholder)
            .opacity(isActive ? 1 : 0.15)
    }
    
    
    private func dreamDateText(dreamDate: String) -> some View {
        Text(dreamDate)
            .font(.body(14, .mediumItalic))
            .multilineTextAlignment(.leading)
            .foregroundStyle(Color.textPrimary)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

//Function Helpers
extension IdealMeetupView {
    
    private func noPreferencesYet() -> Bool {
        return preferredDays.isEmpty && activities.isEmpty && dreamMeetup.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}




/*
 
 struct IdealMeetupView: View {
     
     let vm: EditProfileViewModel
     
     var body: some View {
         Section {
             
             
             
             
             
             
             
             Group {
                 if isEmptyView() {
                     Text("Add Meet Up Preferences")
                         .foregroundStyle(Color.accent)
                         .font(.body(14))
                 } else {
                     VStack(spacing: hasOnlyTwoInputs ? 36 : 24) {
                         typesSelected
                         textSection
                             .padding(.horizontal, 4)
                         selectedDaySection
                             .padding(.horizontal, 4)
                     }
                 }
             }
                 .frame(minHeight: isEmptyView() ? 130 : 0, alignment: .top)
                 .frame(maxWidth: .infinity)
                 .listRowInsets(EdgeInsets(top: hasOnlyAMessage ? 28 : 20, leading: Spacing.md, bottom: hasOnlyAMessage ? 28 : 20, trailing: Spacing.md))
                 .overlay(alignment: .topTrailing) {
                     Image(isEmptyView() ? "EditButton" : "EditGray")
                 }
                 .editorLink(.idealMeetup)
         } header: {
             Text("Meetup Preferences")
                 .padding(.leading, -Spacing.sm) //Geometry: negates the header's row inset so it lines up with the large title
         }
     }
 }

 extension IdealMeetupView {
     
     private var hasOnlyAMessage: Bool {
         hasNote && !hasTypes && !hasDays
     }

     private var hasOnlyTwoInputs: Bool {
         [hasTypes, hasNote, hasDays].filter { $0 }.count == 2
     }
     
     
     
     
     
     
     
     private var typesSelected: some View {
         VStack(alignment: .leading, spacing: 6) {
             if hasTypes {
                 FlowLayout(mode: .scrollable, items: vm.draft.preferredMeetUpType, itemSpacing: Spacing.xs) { type in
                     Text(type)
                         .lineLimit(1)
                         .fixedSize()
                         .font(.body(15, .bold))
                         .foregroundStyle(Color.white)
                         .padding(.horizontal, Spacing.sm)
                         .padding(.vertical, 10)
                         .background(Color.blackFill, in: .capsule)
                 }
                 .padding(.horizontal, -Spacing.xs) //Geometry: negates FlowLayout's per-item itemSpacing padding so the chips sit flush with the label
                 .padding(.vertical, -Spacing.xs) //Geometry: the same padding above the first row and below the last
                 .frame(maxWidth: .infinity, alignment: .leading)
             }
         }
     }
     
     @ViewBuilder
     private var textSection: some View {
         if let note = vm.draft.dreamDateNote, !note.isEmpty {
             Text(note)
                 .font(.body(14, .mediumItalic))
                 .multilineTextAlignment(.leading)
                 .foregroundStyle(Color.textPrimary)
                 .lineSpacing(6)
                 .frame(maxWidth: .infinity, alignment: .leading)
         }
     }
     
     @ViewBuilder
     private var selectedDaySection: some View {
         if hasDays {
             HStack{
                 Text("Preferred Days:")
                     .foregroundStyle(Color(red: 0.65, green: 0.65, blue: 0.65))
                 Spacer(minLength: 24)
                    
                 Group {
                     if vm.draft.availableDays.count > 3 {
                         Text(daysInShort)
                     } else {
                         Text(daysInFull)
                     }
                 }
                 .foregroundStyle(Color(red: 0.53, green: 0.53, blue: 0.53))
             }
             .font(.body(14, .mediumItalic))
         }
     }
     
     private static let week: [(short: String, full: String)] = [
         ("Mon", "Monday"), ("Tue", "Tuesday"), ("Wed", "Wednesday"), ("Thu", "Thursday"),
         ("Fri", "Friday"), ("Sat", "Saturday"), ("Sun", "Sunday")
     ]
     
     private var daysInShort: String {
         Self.week
             .filter{ vm.draft.availableDays.contains($0.short) }
             .map(\.short)
             .joined(separator: ", ")
     }

     private var daysInFull: String {
         Self.week
             .filter { vm.draft.availableDays.contains($0.short) }
             .map(\.full)
             .joined(separator: ", ")
     }

     private func isEmptyView() -> Bool { !hasTypes && !hasNote }
     
     private var hasTypes: Bool { !vm.draft.preferredMeetUpType.isEmpty }
     private var hasDays: Bool { !vm.draft.availableDays.isEmpty }
     private var hasNote: Bool { !(vm.draft.dreamDateNote?.isEmpty ?? true) }
 }
 */

