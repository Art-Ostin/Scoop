//
//  InterestsView.swift
//  Scoop
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

struct InterestsView: View {

    //Injected
    @Bindable var vm: EditProfileViewModel
    @Binding var path: [EditProfileRoute]

    private var interests: [String] { vm.draft.interests }

    //Two interests to a row: every other index starts one and takes the next along if it's there
    private var rowStarts: [Int] { Array(stride(from: 0, to: interests.count, by: 2)) }

    //Half the gap between two interest rows — they sit tighter than a ListItem, with no divider to hold them apart
    private let rowInset = Spacing.md


    var body: some View {
        Section {
            titleRow
            ForEach(rowStarts, id: \.self) { start in
                InterestsRow(left: interests[start],
                             right: start + 1 < interests.count ? interests[start + 1] : nil,
                             topInset: start == 0 ? Spacing.lg : rowInset,
                             bottomInset: rowInset) { path.append(.interests) }
                    .padding(.bottom, start == rowStarts.last ? Spacing.xs - 2 : 0)
            }
            .listRowSeparator(.hidden)
            .padding(.horizontal, 1)
        }
        .listSectionSpacing(Spacing.lg) //Closes the gap to the card above
    }
}

extension InterestsView {

    //A NavigationLink, not a plain heading: it wears the same system chevron as the rows in the cards above, and opens the same screen the pairs do
    private var titleRow: some View {
        NavigationLink(value: EditProfileRoute.interests) {
            Text("Interests")
                .font(.body(.bold))
                .foregroundStyle(Color.textPrimary)
                .offset(y: 0.5) //Geometry: holds the heading still while the row lifts the chevron
        }
            .offset(y: -0.5) //Geometry: the system chevron sits low against the heading's cap height
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: Spacing.md + 2, leading: Spacing.lg,
                                      bottom: 0, trailing: Spacing.lg))
    }
}

private struct InterestsRow: View {

    let left: String
    //Only the last row can come up short, when the interests count is odd
    let right: String?
    var topInset: CGFloat? = nil
    var bottomInset: CGFloat? = nil
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(left)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(right ?? "")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.body(15))
            .foregroundStyle(Color.textSecondary)
        }
        .buttonStyle(.plain)
        .editProfileRow(top: topInset, bottom: bottomInset)
    }
}
