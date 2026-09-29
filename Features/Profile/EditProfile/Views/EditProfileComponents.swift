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
    
    @State private var subHeadingLineCount = 0
    var subHeadingWraps: Bool { hasSubHeading && subHeadingLineCount >= 2 }
    var subHeading: String? = nil

    var response: [String]
        
    let value: Value
    
    var isEmpty: Bool { response.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } }

    //Every year picked reads as "All" — a set, since picks append in tap order
    var writeAll: Bool { Set(response) == Set(OptionField.year.options) }

    var hasSubHeading: Bool { subHeading?.isEmpty == false }

    var body: some View {
        NavigationLink(value: value) {
            HStack {
                Text(title)
                    .font(.body(.bold))
                    .foregroundStyle(Color.textPrimary)
                
                Spacer(minLength: 16)
                
                VStack(alignment: .trailing, spacing: subHeadingLineCount == 2 ? 0 : 2) {
                    Text(isEmpty ? "Add" : (writeAll ? "All" : response.joined(separator: ", ")))
                        .foregroundStyle(isEmpty ? Color.textPlaceholder : Color.textTertiary)
                        .font(.body(15))
                        .multilineTextAlignment(.trailing)
                        .lineLimit(1)
                    
                    if hasSubHeading, let subHeading {
                        Text(subHeading)
                            .font(.body(12, .regularItalic))
                            .foregroundStyle(Color.textTertiary)
                            .lineLimit(2)
                            
                            //To check if the subheading is two lines, if it is apply an offset
                            .onGeometryChange(for: Int.self) { //Rendered height ÷ one line = lines drawn
                                Int(($0.size.height / UIFont.body(12, .regularItalic).lineHeight).rounded())
                            } action: { subHeadingLineCount = $0 }
                    }
                }
                .fixedSize(horizontal: false, vertical: true) //Lays out at its natural height…
                .frame(height: 0)
                .offset(y: subHeadingWraps ? -3 : 0) //A two-line pair sits a touch low, optically centred on the title
            }
        }
        .editProfileRow()
    }
}

extension View {

    //The Edit Profile row box — the insets and separator column every row on the screen shares.
    func editProfileRow(top: CGFloat? = nil, bottom: CGFloat? = nil) -> some View {
        alignmentGuide(.listRowSeparatorTrailing) { $0[.trailing] }
            .listRowSeparatorTint(.borderLight)
            .listRowInsets(EdgeInsets(top: top ?? (Spacing.md + 3), leading: Spacing.lg,
                                      bottom: bottom ?? (Spacing.md + 3), trailing: Spacing.lg))
    }

    func editorLink(_ route: EditProfileRoute) -> some View {
        background { NavigationLink(value: route) { EmptyView() }.opacity(0) }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .listRowBackground(Color.white)
    }
}


