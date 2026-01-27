//
//  OldDropDown.swift
//  Scoop
//
//  Created by Art Ostin on 27/01/2026.
//

import Foundation

/*
 @ViewBuilder
 func OptionsView() -> some View {
     VStack(spacing: 10) {
         ForEach(options, id: \.self) { option in
             HStack(spacing: 0) {
                 Text(option)
                     .lineLimit(1)
                 
                 Spacer(minLength: 0)
                 
                 Image(systemName: "checkmark")
                     .font(.caption)
                     .opacity(selection == option ? 1 : 0)
             }
             .foregroundStyle(selection == option ? Color.primary: Color.gray)
             .frame(height: 40)
             .background(scheme == .dark ? .black : .white)
             .contentShape(.rect)
             .onTapGesture {
                 withAnimation(.snappy) {
                     selection = option
                     showOptions = false
                 }
             }
         }
     }
     .padding(.vertical, 5)
     .padding(.horizontal, 15)
 }

 */

/*
 .onTapGesture {
     index += 1
     zIndex = index
     withAnimation(.snappy) {
         showOptions.toggle()
     }
 }

 */
