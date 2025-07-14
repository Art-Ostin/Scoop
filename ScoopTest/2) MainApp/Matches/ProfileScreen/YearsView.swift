//
//  SelectYears.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI

struct SelectYears: View {
    var body: some View {
        CustomList(title: "Select the years you're open to meeting") {
            HStack(spacing: 24) {
                YearCell(title: "U0", onTap: {})
                YearCell(title: "U1", onTap: {})
                YearCell(title: "U2", onTap: {})
                YearCell(title: "U3", onTap: {})
                YearCell(title: "U4", onTap: {})
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 48)
        .padding(.horizontal, 32)
    }
}

#Preview {
    SelectYears()
}
