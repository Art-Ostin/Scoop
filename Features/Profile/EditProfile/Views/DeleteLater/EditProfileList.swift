//
//  CustomList.swift
//  Scoop
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI






 
 
 struct CustomList<Content: View> : View {

     let content: () -> Content
     var title: String?
     let showInfoText: Bool


     init(
         title: String? = nil,
         showInfoText: Bool = false,
         @ViewBuilder content: @escaping () -> Content
     ){
         self.title = title
         self.showInfoText = showInfoText
         self.content = content
     }
     
     var body: some View {
         VStack(alignment: .leading, spacing: Spacing.xs) {
             if let title = title {
                 Text(title)
                     .font(.body(12, .bold))
                     .foregroundStyle(Color.textTertiary)
                     .padding(.horizontal, Spacing.md)

                 if showInfoText {
                     Text("Choose which map app opens for seeing the locations of events")
                         .infoText()
                         .padding(.horizontal, Spacing.md)
                 }
             }
             VStack(spacing: Spacing.xs) {
                 content()
             }
             .padding(.vertical, Spacing.sm)
             .background(Color.white, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
         }
         .frame(maxWidth: .infinity, alignment: .leading)
     }
 }

 #Preview {
     CustomList(content: {})
 }
