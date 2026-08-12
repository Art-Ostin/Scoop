//
//  ViewProfileButton.swift
//  Scoop
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI

//The Overlay button to toggle between editing the profile and viewing the profile
struct ViewAndEditProfileToggle: View {

    @Binding var isEdit: Bool

    private let textShift: CGFloat = 7.5
    private let arrowShift: CGFloat = 20

    var body: some View {

        ScoopButton(style: .tinted(.textAccent, shadow: .button),
                    shape: .capsule, press: .grow, nativeGlassPress: true) {
            withAnimation(.transition) { isEdit.toggle() }
        } label: {
            ZStack {
                ZStack { //Stable slot: the words swap inside it, the slot itself slides
                    Text(isEdit ? "View" : "Edit")
                        .font(.body(14, .bold))
                        .transition(.blurReplace)
                        .id(isEdit)
                }
                .offset(x: isEdit ? textShift : -textShift)

                //One chevron for both states: turned 180° it *is* chevron.left.
                Image(systemName: "chevron.right")
                    .font(.body(12, .bold))
                    .rotationEffect(.degrees(isEdit ? 180 : 0))
                    .offset(x: isEdit ? -arrowShift : arrowShift, y: -1) //Geometry: -1 optical nudge onto the text
                    .animation(.move, value: isEdit)
            }
            .frame(width: 75, height: 35)
        }
        .padding(.bottom, 48)
    }
}


//The List Item in the lists
struct ListItem<Value: Hashable>: View {
    
    let title: String
    
    var response: [String]
    
    let value: Value
    
    var body: some View {
        let isEmpty = response.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        let writeAll = response == ["U0", "U1", "U2", "U3", "U4"]
        
        NavigationLink(value: value) {
            HStack {
                Text(title)
                    .font(.body(.bold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                //An empty field is a hole, not an action: it stays quieter than a filled one rather than louder
                Text(isEmpty ? "Add" : (writeAll ? "All" : response.joined(separator: ", ")))
                    .foregroundStyle(isEmpty ? Color.textPlaceholder : Color.textTertiary)
                    .font(.body(15))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
            }
        }
        .editProfileRow()
//        .alignmentGuide(.listRowSeparatorTrailing) { $0[.trailing] }
//        .listRowInsets(EdgeInsets(top: Spacing.md + 3, leading: Spacing.lg,
//                                  bottom: Spacing.md + 3, trailing: Spacing.lg))
    }
}



extension View {

    //The Edit Profile row box — the insets and separator column every row on the screen shares.
    //The separator is drawn on the row's own box, so a row that needs to sit tighter overrides the
    //inset here rather than pulling its content up with negative padding — that would slide the text
    //out of its box and leave the divider behind.
    func editProfileRow(top: CGFloat? = nil, bottom: CGFloat? = nil) -> some View {
        alignmentGuide(.listRowSeparatorTrailing) { $0[.trailing] }
            .listRowInsets(EdgeInsets(top: top ?? (Spacing.md + 3), leading: Spacing.lg,
                                      bottom: bottom ?? (Spacing.md + 3), trailing: Spacing.lg))
    }


func listPlainBackground(isBottom: Bool) -> some View {
        self
            .listRowInsets(EdgeInsets(top: 20, leading: Spacing.md, bottom: isBottom ? 20 : Spacing.xxs, trailing: Spacing.md))
            .buttonStyle(.plain)
            .listRowSeparator(.hidden)
    }
}


