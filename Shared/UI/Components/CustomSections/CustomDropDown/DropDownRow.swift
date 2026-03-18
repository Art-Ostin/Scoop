//
//  DropDownRow.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//




struct DropDownRow: View {
    let image: String?
    let text: String
    var body: some View {
        HStack (spacing: 24) {
            if let emoji = image {
               Text(emoji)
            }
            Text(text)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
