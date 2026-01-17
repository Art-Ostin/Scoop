//
//  SelectYears.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI

struct YearsView: View {
    var body: some View {
        CustomList(title: "Years you're open to meeting") {
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
    }
}

#Preview {
    YearsView()
}

struct YearCell: View {

    let title: String
    @State var isSelected: Bool = false
    var onTap: (() -> Void)

    var body: some View {
        Text(title)
            .frame(width: 50, height: 44)
            .font(.body(16, .bold))
            .overlay ( RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.black : Color.grayBackground, lineWidth: 1))
            .foregroundStyle(isSelected ? Color.accent : Color.grayText
            )            .onTapGesture {

                isSelected.toggle()
            }
    }
}
