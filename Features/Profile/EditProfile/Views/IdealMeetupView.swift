//
//  IdealMeetupView.swift
//  Scoop
//
//  Created by Art Ostin on 20/09/2026.
//

import SwiftUI
import SwiftUIFlowLayout

struct IdealMeetupView: View {

    //Injected
    let vm: EditProfileViewModel

    private var preferences: MeetupPreferences { vm.draft.meetupPreferences }
    private var preferredDays: [String] { preferences.preferredDays }
    private var dreamDate: String { preferences.dreamDate.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        Section {
            card
                .accessibilityElement(children: .ignore) //One summary — before editorLink, so its combine keeps the button trait
                .accessibilityLabel("Ideal meetup")
                .accessibilityValue(accessibilitySummary)
                .editorLink(.meetupPreferences)
                .listRowInsets(EdgeInsets(top: Spacing.lg, leading: Spacing.md, bottom: Spacing.lg, trailing: Spacing.md))
        } header: {
            HStack {
                Text("Meetup Preferences")
                    .padding(.leading, -Spacing.sm) //Geometry: negates the header's row inset so it lines up with the large title
                Spacer()
                //On the header, not the card: one editor holds all three answers, so the pencil sits on the group's name
                NavigationLink(value: EditProfileRoute.meetupPreferences) {
                    Image(isEmpty ? "EditButton" : "EditGray")
                        .expandHitArea()
                }
                .buttonStyle(.plain)
                .accessibilityHidden(true) //The card is already the VoiceOver button for this editor
            }
        }
    }
}

//The card: three answers, or one invitation when there are none
extension IdealMeetupView {

    private var card: some View {
        Group {
            if isEmpty {
                addText("Add your ideal meetup")
            } else {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    answer("Go-to dates") { activitiesRow }
                        .meetupBorder(isEmpty: isEmpty)
                    answer("Best days") { dayStrip }
                        .meetupBorder(isEmpty: isEmpty)
                    answer("Dream date") { dreamQuote }
                        .meetupBorder(isEmpty: isEmpty)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading) //Full width even as one short line, so VoiceOver's focus ring frames the card, not the sentence
    }

    private func answer<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .foregroundStyle(Color.textTertiary)
                .font(.body(14))
            content()
        }
    }

    private func addText(_ text: String) -> some View {
        Text(text)
            .font(.body(14))
            .foregroundStyle(Color.textAccent)
    }
}

//What: every pick as a soft tag — three spread across the column, more wrapping onto as many lines as they need
extension IdealMeetupView {

    //The editor's grid order (EditIdealMeetup.rows), not tap order, so the card reads like the grid it was picked from
    private static let activityOrder = [
        "Drinks", "Coffee", "Brunch", "Lunch", "Live Music", "Double Date", "Social Meet",
        "Dinner", "Rave", "A Walk", "Pastries", "A Movie", "Thrifting", "Park", "Ice Cream"
    ]

    private var activities: [String] {
        let picked = preferences.preferredActivities
        return Self.activityOrder.filter { picked.contains($0) }
            + picked.filter { !Self.activityOrder.contains($0) } //An option the grid no longer offers keeps a place at the end
    }

    @ViewBuilder
    private var activitiesRow: some View {
        if activities.isEmpty {
            addText("Add")
        } else if activities.count == 3 {
            ViewThatFits(in: .horizontal) { //A trio too long to spread falls back to the wrap rather than overrunning the card
                spreadTrio
                activitiesFlow
            }
        } else {
            activitiesFlow
        }
    }

    private var spreadTrio: some View {
        HStack(spacing: 36) { //spacing 0: the Spacers carry the gap, so the first and last tags hold the column's edges
            ForEach(activities, id: \.self) { activity in
                activityTag(activity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    //Wraps rather than scrolls, so every pick is on show without a swipe. .scrollable because .vstack collapses to 10pt in a List row — nothing scrolls
    private var activitiesFlow: some View {
        FlowLayout(mode: .scrollable, items: activities, itemSpacing: Spacing.xs) { activity in
            activityTag(activity)
        }
        .padding(-Spacing.xs) //Geometry: negates FlowLayout's itemSpacing padding round every tag, so the block sits flush on the column with the tags 16pt apart
    }

    private func activityTag(_ activity: String) -> some View {
        Text(activity)
            .font(.body(15))
            .foregroundStyle(Color.textPrimary)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .capsuleStroke(lineWidth: 0.5, color: Color.borderLight)
    }
}

//When: the week, with the chosen days as the editor's black dots
extension IdealMeetupView {

    private static let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    @ViewBuilder
    private var dayStrip: some View {
        if preferredDays.isEmpty {
            addText("Add")
        } else {
            HStack(spacing: 0) { //spacing 0: the Spacers carry the gap, so Mon and Sun hold the column's edges (the editor's recipe)
                ForEach(Self.weekdays, id: \.self) { day in
                    dayDot(day)
                    if day != Self.weekdays.last {
                        Spacer(minLength: Spacing.xxs)
                    }
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.large) //The dots are fixed, so larger letters would spill out of them
        }
    }

    private func dayDot(_ day: String) -> some View {
        let isChosen = preferredDays.contains(day)
        return Text(day)
            .font(.body(13, isChosen ? .bold : .medium))
            .foregroundStyle(isChosen ? Color.textPrimary : Color.textPlaceholder)
            .frame(width: 32, height: 32) //Geometry: the dot — the widest day, "Wed", keeps ~5pt of air a side
            .circleStroke(lineWidth: isChosen ? 0.5 : 0, color: isChosen ? Color.border : Color.white)
//            .padding(.top, 2)
    }
}

//Dream date: their own words, on the app's quote bar
extension IdealMeetupView {

    @ViewBuilder
    private var dreamQuote: some View {
        if dreamDate.isEmpty {
            addText("Add")
        } else {
            HStack(spacing: Spacing.sm) {
//                Capsule()
//                    .fill(Color.borderStrong)
//                    .frame(width: 3) //Geometry: Invite History's note bar

                Text(dreamDate)
                    .font(.body(16, .italic))
                    .foregroundStyle(Color.textPrimary)
                    .lineSpacing(6) //The app's quote leading, = Invite History's note
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .fixedSize(horizontal: false, vertical: true) //Only the text sets the height; the bar just fills it
//            .padding(.top, 4) //Bit more padding than the others
        }
    }
}

//State
extension IdealMeetupView {

    private var isEmpty: Bool {
        activities.isEmpty && preferredDays.isEmpty && dreamDate.isEmpty
    }

    //What VoiceOver reads for the card: only the answers given, with full day names
    private var accessibilitySummary: String {
        guard !isEmpty else { return "Add your ideal meetup" }
        let dayNames = Calendar.current.weekdaySymbols //Sunday first, whatever the locale's first weekday
        let days = Self.weekdays.indices
            .filter { preferredDays.contains(Self.weekdays[$0]) }
            .map { dayNames[($0 + 1) % 7] }
        let parts: [String?] = [
            activities.isEmpty ? nil : "What: " + activities.formatted(.list(type: .and)),
            days.isEmpty ? nil : "When: " + days.formatted(.list(type: .and)),
            dreamDate.isEmpty ? nil : "Dream date: " + dreamDate
        ]
        return parts.compactMap { $0 }.joined(separator: ". ")
    }
}


extension View {
     func meetupBorder(isEmpty: Bool) -> some View {
        self
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
            .overlay(RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(isEmpty ? .accent : Color.border, lineWidth: 0.5))
    }
}
