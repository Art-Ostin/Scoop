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


    var body: some View {
        Section {
            titleRow
            ForEach(rowStarts, id: \.self) { start in
                InterestsRow(left: interests[start],
                             right: start + 1 < interests.count ? interests[start + 1] : nil,
                             topInset: start == 0 ? Spacing.lg : nil) { path.append(.interests) }
                    .padding(.bottom, start == rowStarts.last ? Spacing.xs - 2 : 0)
            }
            .padding(.horizontal, 2)
        }
    }
}

extension InterestsView {

    private var titleRow: some View {
        HStack {
            Text("Interests")
                .font(.body(16, .bold))
                .foregroundStyle(Color.black)
            Spacer()
            Image("EditButton")
                .scaleEffect(0.7, anchor: .topTrailing)
        }
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
        .editProfileRow(top: topInset)
    }
}
